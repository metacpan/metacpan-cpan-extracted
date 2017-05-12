## no critic(RCS,VERSION,explicit,Module)
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('Math::Prime::FastSieve');
}
ok( 1, 'Math::Prime::FastSieve loaded.' );
done_testing();
