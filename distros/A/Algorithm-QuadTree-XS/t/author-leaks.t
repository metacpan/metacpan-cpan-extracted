
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

use Test::More;
use Algorithm::QuadTree;

use lib 't/lib';
use QuadTreeUtils;

$QuadTreeUtils::DEPTH = 6;

use constant HAS_TEST_MEMORYGROWTH => eval { require Test::MemoryGrowth; 1 };
plan skip_all => 'This test requires Test::MemoryGrowth module'
	unless HAS_TEST_MEMORYGROWTH;

################################################################################
# This tests whether Algorithm::QuadTree leaks memory
################################################################################

Test::MemoryGrowth::no_growth {
	my $qt = Algorithm::QuadTree->new(
		-xmin  => 0,
		-xmax  => AREA_SIZE,
		-ymin  => 0,
		-ymax  => AREA_SIZE,
		-depth => $QuadTreeUtils::DEPTH
	);

	init_zones $qt, 5;

	$qt->getEnclosedObjects(
		zone_start(1),
		zone_start(1),
		zone_end(1),
		zone_end(1),
	);

	$qt->getEnclosedObjects(
		zone_start(2),
		zone_start(2),
		AREA_SIZE / 2,
	);

	$qt->delete(object_name(2, 2));
	$qt->clear;
}
calls => 50, 'quad tree operations do not leak';

done_testing;
