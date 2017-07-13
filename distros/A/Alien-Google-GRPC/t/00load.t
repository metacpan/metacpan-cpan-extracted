## no critic(RCS,VERSION,explicit,Module)
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('Alien::Google::GRPC');
}
ok( 1, 'Alien::Google::GRPC loaded.' );
done_testing();


