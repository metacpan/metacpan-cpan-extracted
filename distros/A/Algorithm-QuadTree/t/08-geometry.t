use strict;
use warnings;

BEGIN { $ENV{ALGORITHM_QUADTREE_BACKEND} = 'Algorithm::QuadTree::PP'; }

use Test::More;
use Algorithm::QuadTree;

use lib 't/lib';
use QuadTreeUtils;

my $qt = Algorithm::QuadTree->new(
	-xmin  => 0,
	-xmax  => 8,
	-ymin  => 0,
	-ymax  => 8,
	-depth => 2,
);

$qt->add('circle', 1, 1, 1);
$qt->add('rectangle', 6, 6, 8, 8);

# start testing

subtest 'circle vs circle check' => sub {
	my $list = $qt->get(2, 2, 0.4);
	check_array $list, [];

	$list = $qt->get(2, 2, 0.5);
	check_array $list, ['circle'];
};

subtest 'circle vs rectangle check' => sub {
	my $list = $qt->get(5, 5, 1.4);
	check_array $list, [];

	$list = $qt->get(5, 5, 1.5);
	check_array $list, ['rectangle'];
};

subtest 'rectangle vs rectangle check' => sub {
	my $list = $qt->get(5, 5, 5.99, 5.99);
	check_array $list, [];

	$list = $qt->get(5, 5, 6, 6);
	check_array $list, ['rectangle'];
};

subtest 'getApprox and getEnclosedObjects do not check geometry' => sub {
	my $list = $qt->getApprox(5, 5, 5.1, 5.1);
	check_array $list, ['rectangle'];

	$list = $qt->getApprox(5, 5, 0.1);
	check_array $list, ['rectangle'];

	$list = $qt->getEnclosedObjects(5, 5, 5.1, 5.1);
	check_array $list, ['rectangle'];

	$list = $qt->getEnclosedObjects(5, 5, 0.1);
	check_array $list, ['rectangle'];
};

done_testing;

