use strict;
use warnings;

use Test::More;

plan tests => 8;

use lib 't/lib';

use Catalyst::Test qw/AuthTestApp4/;

# All tests happen inside the TestLogger object
# that is loaded in AuthTestApp4

my $o = get("/authed_ok?username=bob&password=bob");

