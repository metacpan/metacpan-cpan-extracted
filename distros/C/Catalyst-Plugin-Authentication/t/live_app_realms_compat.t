use strict;
use warnings;

use Test::More;

BEGIN {
    plan "no_plan";
}

use lib 't/lib';
use Catalyst::Test qw/AuthRealmTestAppCompat/;

ok(get("/moose"), "get ok");
