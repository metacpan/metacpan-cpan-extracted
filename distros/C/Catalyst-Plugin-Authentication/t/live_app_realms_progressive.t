use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Catalyst::Test qw/AuthRealmTestAppProgressive/;

ok(get("/progressive"), "get ok");

done_testing;

