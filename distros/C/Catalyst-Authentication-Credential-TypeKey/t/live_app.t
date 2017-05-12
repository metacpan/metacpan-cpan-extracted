use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Catalyst::Test qw/AuthTestApp/;

BEGIN { use_ok("AuthTestApp" ) }

# ok(get("/moose"), "get ok");

done_testing();
