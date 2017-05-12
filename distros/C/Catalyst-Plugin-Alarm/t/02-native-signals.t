use strict;
use warnings;

BEGIN {
    $ENV{USE_NATIVE_SIGNALS} = 1;
}

use lib 't';
use Catalyst::Test 'TestApp';
use Test::More tests => 7;

# some tests defined in the TestApp files

diag("USE_NATIVE_SIGNALS = $Catalyst::Plugin::Alarm::USE_NATIVE_SIGNALS");

ok( get('/sleeper'),    "get /sleeper" );
ok( get('/sleeper/10'), "get /sleeper/10" );
ok( get('/foo'),        "get /foo" );

1;

