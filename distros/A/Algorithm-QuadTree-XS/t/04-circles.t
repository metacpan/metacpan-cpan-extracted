use strict;
use warnings;

use Test::More;
use Algorithm::QuadTree;

use lib 't/lib';
use QuadTreeUtils;

$QuadTreeUtils::DEPTH = 2;

my $qt = Algorithm::QuadTree->new(
	-xmin  => 0,
	-xmax  => AREA_SIZE,
	-ymin  => 0,
	-ymax  => AREA_SIZE,
	-depth => $QuadTreeUtils::DEPTH
);

# start testing

subtest 'circle should be added to three zones' => sub {
	$qt->add('circle', 4, 4, 1.2);

	my $top_left = $qt->getEnclosedObjects(
		zone_start(0),
		zone_start(0),
		zone_end(0),
		zone_end(0),
	);

	check_array $top_left, ['circle'];

	my $top_right = $qt->getEnclosedObjects(
		zone_start(1),
		zone_start(0),
		zone_end(1),
		zone_end(0),
	);

	check_array $top_right, ['circle'];

	my $bottom_left = $qt->getEnclosedObjects(
		zone_start(0),
		zone_start(1),
		zone_end(0),
		zone_end(1),
	);

	check_array $bottom_left, ['circle'];

	my $bottom_right = $qt->getEnclosedObjects(
		zone_start(1),
		zone_start(1),
		zone_end(1),
		zone_end(1),
	);

	check_array $bottom_right, [];
};

subtest 'circle should be added to all zones' => sub {
	$qt->clear;
	$qt->add('circle2', 4, 4, 1.5);

	my $top_left = $qt->getEnclosedObjects(
		zone_start(0),
		zone_start(0),
		zone_end(0),
		zone_end(0),
	);

	check_array $top_left, ['circle2'];

	my $top_right = $qt->getEnclosedObjects(
		zone_start(1),
		zone_start(0),
		zone_end(1),
		zone_end(0),
	);

	check_array $top_right, ['circle2'];

	my $bottom_left = $qt->getEnclosedObjects(
		zone_start(0),
		zone_start(1),
		zone_end(0),
		zone_end(1),
	);

	check_array $bottom_left, ['circle2'];

	my $bottom_right = $qt->getEnclosedObjects(
		zone_start(1),
		zone_start(1),
		zone_end(1),
		zone_end(1),
	);

	check_array $bottom_right, ['circle2'];
};

subtest 'area to search should work properly for circular shapes' => sub {
	$qt->clear;
	$qt->add('circle3', 4, 4, 0.9);

	my $search_smaller = $qt->getEnclosedObjects(6, 6, 0.6);

	check_array $search_smaller, [], ' (smaller)';

	my $search_medium = $qt->getEnclosedObjects(6, 6, 1.1);

	check_array $search_medium, [], ' (medium)';

	my $search_bigger = $qt->getEnclosedObjects(6, 6, 1.5);

	check_array $search_bigger, ['circle3'], ' (bigger)';
};

done_testing;

