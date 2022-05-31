use strict;
use warnings;

use lib 'lib';

BEGIN { $ENV{ALGORITHM_QUADTREE_BACKEND} = 'Algorithm::QuadTree::PP'; }
use Algorithm::QuadTree;
use Benchmark qw(cmpthese);

my $depth = shift;
$depth ||= 5;

sub run_rectangles
{
	my $qt = Algorithm::QuadTree->new(
		-xmin => 0,
		-xmax => 1000,
		-ymin => 0,
		-ymax => 1000,
		-depth => $depth
	);

	for (1 .. 100) {
		my ($r1, $r2) = (rand 1000, rand 1000);
		$qt->add($_, $r1, $r2, $r1 + 0.2, $r2 + 0.2);
	}

	my $r_list = $qt->getEnclosedObjects(400, 400, 600, 600);
}

sub run_circles
{
	my $qt = Algorithm::QuadTree->new(
		-xmin => 0,
		-xmax => 1000,
		-ymin => 0,
		-ymax => 1000,
		-depth => $depth
	);

	for (1 .. 100) {
		my ($r1, $r2) = (rand 1000, rand 1000);
		$qt->add($_, $r1, $r2, 0.113);
	}

	# roughly the same area as the rectangles case
	my $r_list = $qt->getEnclosedObjects(500, 500, 113);
}

cmpthese -3, {
	rectangles => \&run_rectangles,
	circles => \&run_circles,
};

