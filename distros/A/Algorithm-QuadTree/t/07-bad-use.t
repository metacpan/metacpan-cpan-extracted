use strict;
use warnings;

use Test::More;

$ENV{ALGORITHM_QUADTREE_BACKEND} = 'Backend::NonExistent';
eval {
	require Algorithm::QuadTree;
};

like $@, qr{\QCan't locate Backend/NonExistent.pm\E}, 'error ok';

done_testing;

