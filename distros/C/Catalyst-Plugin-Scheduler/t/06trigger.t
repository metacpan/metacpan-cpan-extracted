#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use Storable qw/lock_store lock_retrieve/;

plan tests => 6;
use Catalyst::Test 'TestApp';

our $STATE = "$FindBin::Bin/lib/TestApp/scheduler.state";

TestApp->schedule(
    trigger  => 'every_minute',
    event    => '/cron/every_minute',
);

# disallow localhost
TestApp->config->{scheduler}->{hosts_allow} = '1.2.3.4';

# test that the event does not execute
{
    ok( my $res = request('http://localhost/?schedule_trigger=every_minute'), 'request ok' );
    is( $res->content, 'default', 'response ok' );
    is( -e "$FindBin::Bin/lib/TestApp/every_minute.log", undef, 'every_minute did not execute, ok' );
    unlink "$FindBin::Bin/lib/TestApp/every_minute.log";
}

# allow localhost
TestApp->config->{scheduler}->{hosts_allow} = [ '1.2.3.4', '127.0.0.1' ];

# test that the event does execute
{
    ok( my $res = request('http://localhost/?schedule_trigger=every_minute'), 'request ok' );
    is( $res->content, 'default', 'response ok' );
    is( -e "$FindBin::Bin/lib/TestApp/every_minute.log", 1, 'every_minute executed ok' );
    unlink "$FindBin::Bin/lib/TestApp/every_minute.log";
}
