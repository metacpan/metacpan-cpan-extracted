use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/lib";

use Test::More;

BEGIN {
    defined($ENV{SESSION_STORE_REDIS_URL}) or plan skip_all => 'Must set SESSION_STORE_REDIS_URL environment variable';
}

use Catalyst::Test "SessionStoreTest";

my $x = get("/store_scalar");
is(get('/get_scalar'), 456, 'Can store scalar value okay');
