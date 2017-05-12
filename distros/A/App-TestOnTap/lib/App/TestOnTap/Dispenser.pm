package App::TestOnTap::Dispenser;

use strict;
use warnings;

use App::TestOnTap::Util qw(slashify);
use App::TestOnTap::OrderStrategy;

use File::Find;

# CTOR
#
sub new
{
	my $class = shift;
	my $args = shift;

	my $self = bless( { args => $args, inprogress => {}, orderstrategy => App::TestOnTap::OrderStrategy->new() }, $class);
	$self->__analyze(); 
	
	return $self;
}

sub __analyze
{
	my $self = shift;

	# find all tests in the suite root
	# (subject to config skip filtering)
	#	
	my $tests = $self->__scan();

	# create a graph with all the tests as 'from' vertices, begin with no dependencies
	#
	my %graph = map { $_ => [] } @$tests;
	
	# iterate over all dependency rules and add edges from => to vertices
	#
	foreach my $depRuleName ($self->{args}->getConfig()->getDependencyRuleNames())
	{
		my ($fromVertices, $toVertices) = $self->{args}->getConfig()->getMatchesAndDependenciesForRule($depRuleName, $tests);
		push(@{$graph{$_}}, @$toVertices) foreach (@$fromVertices);
	}
	
	$self->{args}->getWorkDirManager()->recordFullGraph(%graph);
		
	# trap any cyclic dependency problems right now
	#
	$self->__toposort(\%graph);

	# tentatively store the full graph
	#
	$self->{graph} = \%graph;
	
	# if user decided to supply a skip filter, now try to create a
	# graph filtered to matching tests, but without including dependencies...
	#
	my $prunedTests = $self->{args}->include($tests);
	
	# ...but now make sure dependencies are brought along whether
	# they we're filtered in or not...
	#
	if ($prunedTests && scalar(@$prunedTests) != scalar(@$tests))
	{
		my %prunedGraph;

		# iteratively pick up all tests and dependencies
		# as long as we're picking up new deps, we need to iterate again
		#
		my @newDeps = @$prunedTests;
		while (my $t = shift(@newDeps))
		{
			if (!exists($prunedGraph{$t}))
			{
				$prunedGraph{$t} = $graph{$t};
				push(@newDeps, @{$prunedGraph{$t}});
			}
		}
		
		# store the pruned graph instead
		#
		$self->{graph} = \%prunedGraph;
		
		$self->{args}->getWorkDirManager()->recordPrunedGraph(%prunedGraph);
	}
}

sub getAllTests
{
	my $self = shift;
	
	return keys(%{$self->{graph}});
}

sub getEligibleTests
{
	my $self = shift;
	my $completed = shift || [];
	
	# remove items that have been completed from the graph
	#
	foreach my $t (@$completed)
	{
		delete($self->{graph}->{$t});
		delete($self->{inprogress}->{$t});
	}

	# no more items to run at all - we're finished
	#
	return unless keys(%{$self->{graph}});
	
	# if we're still here, remove any references to completed tests
	# from the remaining tests
	#
	foreach my $removed (@$completed)
	{
		foreach my $t (keys(%{$self->{graph}}))
		{
			$self->{graph}->{$t} = [ grep( !/^\Q$removed\E$/, @{$self->{graph}->{$t}} ) ];
		}
	}

	# extract those ready to run and separate them into parallelizable and not parallelizable
	#
	my @parallelizable;
	my @nonParallelizable;
	foreach my $t (keys(%{$self->{graph}}))
	{
		# tests that have no dependencies and are not already in progress are
		# now ready to run
		# 
		if (!@{$self->{graph}->{$t}} && !$self->{inprogress}->{$t})
		{
			if ($self->{args}->getConfig()->parallelizable($t))
			{
				push(@parallelizable, $t);
			}
			else
			{
				push(@nonParallelizable, $t);
			}
		}
	}	

	# order them according to the chosen strategy
	#
	my $orderstrategy = $self->{args}->getOrderStrategy() || $self->{args}->getConfig()->getOrderStrategy() || $self->{orderstrategy}; 
	$self->{args}->getWorkDirManager()->recordOrderStrategy($orderstrategy);
	@parallelizable = $orderstrategy->orderList(@parallelizable);
	@nonParallelizable = $orderstrategy->orderList(@nonParallelizable);
	
	# now finally select those eligible - try to do away with parallelizabe first
	#
	my @eligible = @parallelizable;
	
	# we only deal with non-parallelizables if:
	#   - nothing else already is eligible
	#   - there are any to deal out at all...
	#   - nothing else is presently in progress
	# if so, just pick the first
	# 
	if (!@eligible && @nonParallelizable && !keys(%{$self->{inprogress}}))
	{
		@eligible = $nonParallelizable[0];
	}
	
	# make a note that those we return are in progress
	#
	$self->{inprogress}->{$_} = 1 foreach (@eligible);

	$self->{args}->getWorkDirManager()->recordDispensedOrder(@eligible);
	
	return \@eligible;
}

# SUB helpers
#

# scan the suite root and find all tests
# (subject to the config skip filter)
#
sub __scan
{
	my $self = shift;

	my $config = $self->{args}->getConfig();
	
	my @tests;
	
	# to simplify during preprocessing, ensure we have a suite root using forward slashes
	#
	my $srfs = slashify($self->{args}->getSuiteRoot(), '/');
	
	# set up a File::Find preprocessor in order to weed out parts of the scanned tree
	# that are selected by the optional config skip filter
	#
	my $preprocess =
		sub
		{
			# stash entries that should be further processed here
			#
			my @keep;
			
			foreach my $entry (@_)
			{
				# skip the '.' and '..' entries
				#
				next if $entry =~ /^\.\.?$/;
				
				# skip any config entries
				#
				next if $entry eq $config->getName();
				
				# skip entries that are not selected by the config filter
				# however, filters are written assuming they're passed paths
				# relative from the suiteroot, and delimited by '/' so construct strings
				# to conform by first normalizing and then stripping the absolute part
				# to the suite root; ensure dirs are suffixed by a '/'.
				#
				my $p = slashify("$File::Find::dir/$entry", '/');
				$p .= '/' if -d $p;
				$p =~ s#^\Q$srfs\E/##;
				next if $config->skip($p);
				
				push(@keep, $entry);
			}
			
			# return the list of entries that should be further processed by the wanted function
			#
			return @keep;
		};
	
	# set up a wanted processor to select tests based on the execmapper
	#
	my $wanted =
		sub
		{
			# normalize the full name
			#
			my $fn = slashify($File::Find::name, '/');
			
			# ignore any directories (they can't be tests anyway)
			#
			return if -d $fn;
			
			# normalize to test name
			#
			$fn =~ s#^\Q$srfs\E/##;

			# ignore files with extensions not handled by the exec mapper
			#			
			return unless $config->hasExecMapping($fn);

			# store it as a test!
			#
			push(@tests, $fn);
		};
	
	# execute the find
	#
	find( { preprocess => $preprocess, wanted => $wanted }, $srfs);
	
	$self->{args}->getWorkDirManager()->recordFoundTests(@tests);
	
	return \@tests;
}

# essentially follows the algorithm for depth-first search as described
# at https://en.wikipedia.org/wiki/Topological_sorting
#
# minor change is that since we will use the toposort
# bottom-up, we push to tail of L instead of unshift to head
# 
sub __toposort
{
	my $self = shift;
	my $graph = shift;
	
	my ($unmarked, $tmpmarked, $permmarked) = (0, 1, 2);
	my @keys = keys(%$graph);
	my %g = map { $_ => { deps => $graph->{$_}, mark => $unmarked } } @keys;

	my @sorted;

	my $visitor;
	$visitor =
		sub
		{
			my $node = shift;
			my @route = @_;
			
			die("ERROR: Cyclic dependency detected: " . join(' => ', @route, $node) . "!\n") if ($g{$node}->{mark} == $tmpmarked);

			return if $g{$node}->{mark};
			
			$g{$node}->{mark} = $tmpmarked;
			$visitor->($_, @route, $node) foreach (@{$g{$node}->{deps}});
			$g{$node}->{mark} = $permmarked;
			push(@sorted, $node);
		};
	
	foreach my $node (@keys)
	{
		next unless $g{$node}->{mark} == $unmarked;
		$visitor->($node);
	}

	return @sorted;
}

1;
