use strict;
use lib 't';
use Catalyst::Test 'TestApp';
use Test::More tests => 7;

diag("USE_NATIVE_SIGNALS = $Catalyst::Plugin::Alarm::USE_NATIVE_SIGNALS");

# some tests defined in the TestApp files

ok( get('/sleeper'),    "get /sleeper" );
ok( get('/sleeper/10'), "get /sleeper/10" );
ok( get('/foo'),        "get /foo" );

1;

