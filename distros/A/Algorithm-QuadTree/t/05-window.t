use strict;
use warnings;

BEGIN { $ENV{ALGORITHM_QUADTREE_BACKEND} = 'Algorithm::QuadTree::PP'; }

use Test::More;
use Algorithm::QuadTree;

use lib 't/lib';
use QuadTreeUtils;

my $qt = Algorithm::QuadTree->new(
	-xmin  => 0,
	-xmax  => 12,
	-ymin  => 0,
	-ymax  => 12,
	-depth => 3
);

subtest 'should be able to set window once' => sub {
	$qt->setWindow(0.5, 0.5, 2);

	is $qt->{SCALE}, 2, 'scale ok';
	is $qt->{ORIGIN}[0], 0.5, 'origin x ok';
	is $qt->{ORIGIN}[1], 0.5, 'origin y ok';
};

subtest 'should be able to set window twice' => sub {
	$qt->setWindow(0.5, 0.5, 2);

	is $qt->{SCALE}, 4, 'scale ok';
	is $qt->{ORIGIN}[0], 0.75, 'origin x ok';
	is $qt->{ORIGIN}[1], 0.75, 'origin y ok';
};

subtest 'should be able to add and get objects when window is set' => sub {
	# should only be in most top left zone
	$qt->add('test1', 8, 8, 8.8, 8.8);

	# should only be in second most top left zone (one to the right to the prev one)
	$qt->add('test2', 9.1, 8, 9.3, 8.8);

	check_array $qt->getEnclosedObjects(1, 1, 7.9), ['test1'], ' (circular, first zone)';
	check_array $qt->getEnclosedObjects(2, 1.5, 7), ['test1', 'test2'], ' (circular, both zones)';

	check_array $qt->getEnclosedObjects(3, 8, 8, 8.5), ['test1'], ' (rectangular, first zone)';
	check_array $qt->getEnclosedObjects(5, 8.4, 9, 9.5), ['test1', 'test2'], ' (rectangular, both zones)';
};

subtest 'should be able to reset window' => sub {
	$qt->resetWindow;
	is $qt->{SCALE}, 1, 'scale ok';
	is $qt->{ORIGIN}[0], 0, 'origin x ok';
	is $qt->{ORIGIN}[1], 0, 'origin y ok';
};

subtest 'should be able to get objects after resetting window' => sub {
	check_array $qt->getEnclosedObjects(1.5, 1.5, 1.4), ['test1'], ' (first zone)';
	check_array $qt->getEnclosedObjects(2.9, 3.1, 0.2), ['test1', 'test2'], ' (both zones)';
};

done_testing;

