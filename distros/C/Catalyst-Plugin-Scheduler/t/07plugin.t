#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use Storable qw/lock_store lock_retrieve/;

plan tests => 3;
use Catalyst::Test 'PluginTestApp';

our $STATE = "$FindBin::Bin/lib/TestApp/scheduler.state";

# hack the last event check to make all events execute immediately
my $state = { last_check => 0 };
lock_store $state, $STATE;

# test that the plugin event executes
{
    ok( my $res = request('http://localhost/'), 'request ok' );
    is( $res->content, 'default', 'response ok' );
    is( -e "$FindBin::Bin/lib/TestApp/plugin_test.log", 1, 'every_minute executed ok' );
    unlink "$FindBin::Bin/lib/TestApp/plugin_test.log";
}

