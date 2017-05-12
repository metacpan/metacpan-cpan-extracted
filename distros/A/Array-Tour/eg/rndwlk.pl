#!/usr/bin/perl
#
use Getopt::Long;
use Data::Dumper;
use Array::Tour qw(:directions);
use Array::Tour::RandomWalk;

use strict;
use warnings;

require "t/helper.pl";

my $rnd_wlk;
my @grid;

my($cols, $rows, $lvls) = (5, 5, 1);
my $backtrack = 'q';
my $walkdonttalk = 0;
my $seed;

GetOptions("cols=i" => \$cols,
	"rows=i" => \$rows,
	"lvls=i" => \$lvls,
	"backtrack=s" => \$backtrack,
	"Seed=i" => \$seed,
	"Walk" => \$walkdonttalk,
);

srand($seed) if (defined $seed);

$backtrack = 'random' if ($backtrack eq 'r');
$backtrack = 'stack' if ($backtrack eq 's');
$backtrack = 'queue' unless ($backtrack =~ /r|s/);

$rnd_wlk = Array::Tour::RandomWalk->new(
		dimensions => [$cols, $rows, $lvls],
		backtrack => $backtrack,
		);

if ($walkdonttalk)
{
	#
	# We're going to cheat and use the internal array in the $rnd_wlk
	# object to print out the grid.  This makes the loop very simple.
	#
	while (my $cref = $rnd_wlk->next())
	{
		my @coords = @{$cref};
	}
}
else
{
	walktour($rnd_wlk);
}

#my $dmp = Data::Dumper->new($rnd_wlk->get_array());
#print $dmp->Dump, "\n\n\n";
#print $rnd_wlk->dump_array();
print ascii_grid($rnd_wlk), "\n";
exit(0);

sub ascii_grid
{
	my($tour) = @_;
	my $m = $tour->get_array();
	my($c_lim, $r_lim, $l_lim) = map {$_ - 1} $tour->get_dimensions();
	my @lvls;

	for my $l (0..$l_lim)
	{
		my $lvl_str = "";
		for my $r (0..$r_lim)
		{
			for my $c (0..$c_lim)
			{
				$lvl_str .= (($$m[$l][$r][$c] & North) == North)? ":  ": ":--";
			}
			$lvl_str .= ":\n";

			for my $c (0..$c_lim)
			{
				$lvl_str .= (($$m[$l][$r][$c] & West) == West)? "   ": "|  ";
			}
			$lvl_str .= (($$m[$l_lim][$r][$c_lim] & East) == East)? ' \n': "|\n";
		}
		for my $c (0..$c_lim)
		{
			$lvl_str .= (($$m[$l][$r_lim][$c] & South) == South)? ":  ": ":--";
		}
		$lvl_str .= ":\n";

		push @lvls, $lvl_str;
	}
	return wantarray? @lvls: join "\n", @lvls;
}

sub walktour
{
	my $tour = shift;
	my($width, $height) = $tour->get_dimensions();

	while (my $cref = $tour->next())
	{
		my @coords = @{$cref};
		if ($tour->direction() == SetPosition)
		{
			print "Jumped to position [", join(", ", @coords), "]\n";
		}
		else
		{
			print "Walked ", $tour->say_direction(), " to [", join(", ", @coords), "]\n";
		}
	}
}

1;
