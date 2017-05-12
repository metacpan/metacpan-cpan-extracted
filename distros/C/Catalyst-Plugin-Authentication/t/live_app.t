use strict;
use warnings;

use Test::More;

BEGIN {
    plan skip_all => "Digest::SHA1 is required for this test" unless eval { require Digest::SHA1 };
    plan "no_plan";
}

use lib 't/lib';
use Catalyst::Test qw/AuthTestApp/;

ok(get("/moose"), "get ok");
