#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;

plan skip_all 
    => 'set TEST_LONG to enable this test.  It takes about 1 minute to run.' 
    unless $ENV{TEST_LONG};
    
plan tests => 6;
use Catalyst::Test 'TestApp';

TestApp->schedule(
    at    => '* * * * *',
    event => '/cron/every_minute',
);

# test that the event does not execute when we first start up
{
    ok( my $res = request('http://localhost/'), 'request ok' );
    is( $res->content, 'default', 'response ok' );
    is( -e "$FindBin::Bin/lib/TestApp/every_minute.log", undef, 'every_minute did not execute, ok' );
    unlink "$FindBin::Bin/lib/TestApp/every_minute.log";
}

# wait for a minute
sleep 61;

# test that the event does execute
{
    ok( my $res = request('http://localhost/'), 'request ok' );
    is( $res->content, 'default', 'response ok' );
    is( -e "$FindBin::Bin/lib/TestApp/every_minute.log", 1, 'every_minute executed ok' );
    unlink "$FindBin::Bin/lib/TestApp/every_minute.log";
}
