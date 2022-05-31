use strict;
use warnings;

use Test::More;
use Algorithm::QuadTree;

use lib 't/lib';
use QuadTreeUtils;

my $qt = Algorithm::QuadTree->new(
	-xmin  => 0,
	-xmax  => AREA_SIZE,
	-ymin  => 0,
	-ymax  => AREA_SIZE,
	-depth => $QuadTreeUtils::DEPTH
);

# add one object per zone
init_zones $qt;

# start testing

subtest 'areas fully inside zones should return just one node' => loop_zones {
	my ($x_zone, $y_zone) = @_;

	my $list = $qt->getEnclosedObjects(
		zone_start($x_zone),
		zone_start($y_zone),
		zone_end($x_zone),
		zone_end($y_zone),
	);

	check_array $list, [object_name($x_zone, $y_zone)];
};

subtest 'areas on zone edges should return two nodes (x)' => loop_zones {
	my ($x_zone, $y_zone) = @_;
	return if $x_zone == 0;

	my $list = $qt->getEnclosedObjects(
		zone_start($x_zone - 1),
		zone_start($y_zone),
		zone_end($x_zone),
		zone_end($y_zone),
	);

	check_array $list, [object_name($x_zone - 1, $y_zone), object_name($x_zone, $y_zone)];
};

subtest 'areas on zone edges should return two nodes (x)' => loop_zones {
	my ($x_zone, $y_zone) = @_;
	return if $y_zone == 0;

	my $list = $qt->getEnclosedObjects(
		zone_start($x_zone),
		zone_start($y_zone - 1),
		zone_end($x_zone),
		zone_end($y_zone),
	);

	check_array $list, [object_name($x_zone, $y_zone - 1), object_name($x_zone, $y_zone)];
};

subtest 'areas on zone vertices should return four nodes' => loop_zones {
	my ($x_zone, $y_zone) = @_;
	return if $x_zone == 0 || $y_zone == 0;

	my $list = $qt->getEnclosedObjects(
		zone_start($x_zone - 1),
		zone_start($y_zone - 1),
		zone_end($x_zone),
		zone_end($y_zone),
	);

	check_array $list, [
		object_name($x_zone - 1, $y_zone - 1),
		object_name($x_zone - 1, $y_zone),
		object_name($x_zone, $y_zone - 1),
		object_name($x_zone, $y_zone),
	];
};

subtest 'full zone area should return all the objects from surrounding zones' => sub {
	my $list = $qt->getEnclosedObjects(
		zone_bound(1),
		zone_bound(1),
		zone_bound(2),
		zone_bound(2),
	);

	check_array $list, [
		object_name(0, 0),
		object_name(0, 1),
		object_name(0, 2),

		object_name(1, 0),
		object_name(1, 1),
		object_name(1, 2),

		object_name(2, 0),
		object_name(2, 1),
		object_name(2, 2),
	];
};

done_testing;

