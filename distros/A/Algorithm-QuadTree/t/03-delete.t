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

# add two objects per zone
init_zones $qt, 2;

# start testing

subtest 'we should be able to delete a node' => sub {
	# delete somewhere in the middle
	$qt->delete(object_name(2, 2));

	# get all objects
	my $list = $qt->getEnclosedObjects(
		0,
		0,
		AREA_SIZE,
		AREA_SIZE,
	);

	is scalar @$list, zones_per_dimension() ** 2 * 2 - 1, 'object count ok';
};

subtest 'we should be able to clear a tree' => sub {
	$qt->clear;

	# get all objects
	my $list = $qt->getEnclosedObjects(
		0,
		0,
		AREA_SIZE,
		AREA_SIZE,
	);

	is scalar @$list, 0, 'object count ok';
};

done_testing;

