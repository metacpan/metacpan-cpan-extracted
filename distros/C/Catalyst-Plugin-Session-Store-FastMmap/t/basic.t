use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/lib";

use Catalyst::Test "SessionStoreTest";
use Test::More;

my $x = get("/store_scalar");
is(get('/get_scalar'), 456, 'Can store scalar value okay');
