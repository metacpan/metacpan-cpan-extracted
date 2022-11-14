use strict;
use warnings;

use lib 'lib';

# BEGIN { $ENV{ALGORITHM_QUADTREE_BACKEND} = 'Algorithm::QuadTree::PP'; }
use Algorithm::QuadTree;
use Benchmark qw(cmpthese);

my $depth = shift;
$depth ||= 8;

my $qt = Algorithm::QuadTree->new(
	-xmin => 0,
	-xmax => 100,
	-ymin => 0,
	-ymax => 100,
	-depth => $depth
);

for (1 .. 100) {
	my ($r1, $r2) = (rand 100, rand 100);
	$qt->add($_, $r1, $r2, $r1 + 0.2, $r2 + 0.2);
}

sub run_rectangles
{
	my $r_list = $qt->getEnclosedObjects(20, 20, 80, 80);
}

sub run_circles
{
	my $r_list = $qt->getEnclosedObjects(50, 50, 34);
}

cmpthese -3, {
	rectangles => \&run_rectangles,
	circles => \&run_circles,
};

