package App::Pods2Site::PodFinder;

use strict;
use warnings;

use App::Pods2Site::Util qw(createSpinner);

use Pod::Simple::Search;
use Grep::Query qw(qgrep);

# CTOR
#
sub new
{
	my $class = shift;
	my $args = shift;

	my $self = bless( {}, $class);
	$self->__scan($args);

	return $self;
}

sub getCount
{
	my $self = shift;
	
	return $self->{count};
}

sub getScriptN2P
{
	my $self = shift;
	
	return $self->{n2p}->{script}; 	
}

sub getCoreN2P
{
	my $self = shift;
	
	return $self->{n2p}->{core}; 	
}

sub getPragmaN2P
{
	my $self = shift;
	
	return $self->{n2p}->{pragma}; 	
}

sub getModuleN2P
{
	my $self = shift;
	
	return $self->{n2p}->{module}; 	
}

sub __scan
{
	my $self = shift;
	my $args = shift;

	# set up some progress feedback
	#
	my $spinner = createSpinner($args);
	my $cb = sub
		{
			my $p = shift;
			my $n = shift;
			
			if ($args->isVerboseLevel(3))
			{
				print "Scanning '$n' => '$p'...\n";
			}
			else
			{
				$spinner->();
			}
		};
	
	# the search can be verbose, but we typically don't want it
	#
	my $verbosity = 0;
	$verbosity++ if $args->isVerboseLevel(4);
	$verbosity++ if $args->isVerboseLevel(5);

	# get all script pods - be 'laborious' since they typically don't fit '.pm' or '.pod' naming
	#
	my $binSearch = Pod::Simple::Search->new()->inc(0)->laborious(1)->callback($cb)->verbose($verbosity);
	$binSearch->survey($args->getBinDirs());
	my $bin_n2p = $binSearch->name2path;
	my @scriptNames = keys(%$bin_n2p); 
		
	# get all other pods - specifically turn off automatic 'inc', since that's part of
	# our own setup
	#
	my $libSearch = Pod::Simple::Search->new()->inc(0)->callback($cb)->verbose($verbosity);
	$libSearch->survey($args->getLibDirs());
	my $lib_n2p = $libSearch->name2path();

	# now separate the pod names up into the remaining categories
	#
	my (@coreNames, @pragmaNames, @moduleNames);
	foreach my $name (keys(%$lib_n2p))
	{
		if (($name =~ /^(?:pods::)?perl/ && $lib_n2p->{$name} =~ /\.pod$/)|| $name =~ /^README$/)
		{
			# observational:
			# - they sometimes live in the pods namespace, other times in the top
			# - I just happened to find a README in the top in an AP distro
			#
			push(@coreNames, $name);
		}
		elsif ($name =~ /^[a-z]/ && $lib_n2p->{$name} =~ /\.pm$/)
		{
			# well, assume every bona fide pm with a lowercase start of the name == pragma
			#
			push(@pragmaNames, $name);
		}
		else
		{
			push(@moduleNames, $name);
		}
	}

	# now apply the users filter (if any) on the names, and store the resulting name2path
	#
	my (%scriptn2p, %coren2p, %pragman2p, %modulen2p);
	my %h =
		(
			script => [ \@scriptNames, \%scriptn2p, $bin_n2p ],
			core => [ \@coreNames, \%coren2p, $lib_n2p ],
			pragma => [ \@pragmaNames, \%pragman2p, $lib_n2p ],
			module => [ \@moduleNames, \%modulen2p, $lib_n2p ],
		);
	$self->{n2p} = {};
	while (my ($sec, $vars) = each(%h))
	{
		my ($names, $n2p, $fulln2p) = @$vars;
		my $filter = $args->getFilter($sec);
		@$names = qgrep("NOT ( $filter )", @$names) if $filter;
		$n2p->{$_} = $fulln2p->{$_} foreach (@$names);
		$self->{n2p}->{$sec} = $n2p;
	}

	$self->{count} = scalar(@scriptNames) + scalar(@coreNames) + scalar(@pragmaNames) + scalar(@moduleNames);
}

1;
