package App::Pods2Site::PodFinder;

use strict;
use warnings;

our $VERSION = '1.003';
my $version = $VERSION;
$VERSION = eval $VERSION;

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

sub getCounts
{
	my $self = shift;
	
	my $sum = 0;
	my %partCounts;
	foreach my $group (@{$self->{groups}})
	{
		my $name = $group->{name};
		my $count = scalar(@{$group->{pods}});
		$partCounts{$name} = $count; 
		$sum += $count;
	}
	
	return ($sum, \%partCounts);
}

sub getGroups
{
	my $self = shift;
	
	return $self->{groups}; 	
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

	# array to use for queries later, holds hash records
	#
	my @podRecords;
	
	# get all script pods - be 'laborious' since they typically don't fit '.pm' or '.pod' naming
	#
	my $binSearch = Pod::Simple::Search->new()->inc(0)->laborious(1)->callback($cb)->verbose($verbosity)->is_case_insensitive(0);
	$binSearch->survey($args->getBinDirs());
	my $bin_n2p = $binSearch->name2path;
	foreach my $name (keys(%$bin_n2p))
	{
		push(@podRecords, { type => 'bin', name => $name, path => $bin_n2p->{$name} });
	}
	
	# get all other pods - specifically turn off automatic 'inc', since that's part of
	# our own setup
	#
	my $libSearch = Pod::Simple::Search->new()->inc(0)->callback($cb)->verbose($verbosity)->is_case_insensitive(0);
	$libSearch->survey($args->getLibDirs());
	my $lib_n2p = $libSearch->name2path();
	foreach my $name (keys(%$lib_n2p))
	{
		if ($name =~ /^(?:pods::)?(perl.+)/)
		{
			# if we see a perlxxx pod in namespace 'pods::', we put it in root level
			# as links go to 'perlxxx' rather than 'pods::perlxxx'
			# 
			push(@podRecords, { type => 'corepod', name => $1, path => $lib_n2p->{$name} });
		}
		else
		{
			push(@podRecords, { type => 'lib', name => $name, path => $lib_n2p->{$name} });
		}
	}

	# use the group queries to separate them
	#
	my @groups;
	foreach my $groupDef (@{$args->getGroupDefs()})
	{
		# remember to pass a file accessor since queries use fields (at least they should!)
		# but we can pass in undef to get the query to manufacture one for us as it's simple hash values
		#
		my @pods = $groupDef->{query}->qgrep(undef, @podRecords);
		push(@groups, { name => $groupDef->{name}, pods => \@pods }); 
	}
	$self->{groups} = \@groups;
}

1;
