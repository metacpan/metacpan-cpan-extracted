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

my $ref1 = ['a reference'];
my $ref2 = ['another reference', $ref1];

# we don't care about coordinates, we just want to test whether the references
# are preserved
$qt->add($ref1, 1, 1, 1);
$qt->add($ref2, 1, 1, 1);

subtest 'should be able to fetch references' => sub {
	my $objects = $qt->getEnclosedObjects(0, 0, AREA_SIZE, AREA_SIZE);

	check_array $objects, [$ref1, $ref2];

	my $len0 = @{$objects->[0]};
	my $ind = $len0 == 2 ? 0 : 1;
	is $objects->[$ind][1][0], 'a reference', 'reference preserved ok';
};

done_testing;

