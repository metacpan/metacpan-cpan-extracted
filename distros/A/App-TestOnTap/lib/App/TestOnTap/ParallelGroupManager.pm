package App::TestOnTap::ParallelGroupManager;

use strict;
use warnings;

our $VERSION = '1.001';
my $version = $VERSION;
$VERSION = eval $VERSION;

use Grep::Query;
use List::MoreUtils qw(singleton);

# CTOR
#
sub new
{
	my $class = shift;
	my $cfg = shift;

	my $self = bless( {}, $class);
	$self->__parseParallelGroups($cfg);
	
	return $self;
}

sub cull
{
	my $self = shift;
	my $inprogress = shift;
	my $eligible = shift;

	return () unless @$eligible;
	
	foreach my $pgname (sort(keys(%{$self->{pargroups}})))
	{
		my $matcher = $self->{pargroups}->{$pgname}->{match};
		my $maxconcurrent = $self->{pargroups}->{$pgname}->{maxconcurrent};
		
		my @matchingInprogress = $matcher->qgrep(@$inprogress);
		my @matchingEligible = $matcher->qgrep(@$eligible);

		my @allmatching = (@matchingInprogress, @matchingEligible);
		my $leave = scalar(@allmatching) - $maxconcurrent;
		$leave = 0 if $leave < 0;
		shift(@allmatching) while (@allmatching > $leave);
		@$eligible = singleton(@allmatching, @$eligible);
	}
	
	return @$eligible;
}

sub __parseParallelGroups
{
	my $self = shift;
	my $cfg = shift;

	my %parGroups;
	# find all parallelgroup sections
	#
	my $pgRx = qr(^\s*PARALLELGROUP\s+(.+?)\s*$);
	foreach my $pgRuleSectionName (grep(/$pgRx/, keys(%$cfg)))
	{
		$pgRuleSectionName =~ /$pgRx/;
		my $pgRuleName = $1;
		
		# all pg sections requires 'match' Grep::Query queries
		# in case match is written as array, just join using newlines
		#
		my $match = $cfg->{$pgRuleSectionName}->{match}; 
		die("Missing key 'match' in parallel group rule section '$pgRuleName'\n") unless defined($match);
		$match = join("\n", @$match) if ref($match) eq 'ARRAY';
		$parGroups{$pgRuleName}->{match} = Grep::Query->new($match);

		# all pg sections requires 'maxconcurrent' positive integer values
		#
		my $maxconcurrent = $cfg->{$pgRuleSectionName}->{maxconcurrent}; 
		die("Missing key 'maxconcurrent' in parallel group rule section '$pgRuleName'\n") unless defined($maxconcurrent);
		die("Illegal value for 'maxconcurrent' in parallel group rule section '$pgRuleName'\n") unless $maxconcurrent > 1;
		$parGroups{$pgRuleName}->{maxconcurrent} = $maxconcurrent;
				
		# check for unknown keys...
		#
		my %validSectionKeys = map { $_ => 1 } qw(match maxconcurrent);
		foreach my $key (keys(%{$cfg->{$pgRuleSectionName}}))
		{
			warn("WARNING: Unknown key '$key' in section '[$pgRuleSectionName]'\n") unless exists($validSectionKeys{$key});
		}
	}
	$self->{pargroups} = \%parGroups;
}

1;
