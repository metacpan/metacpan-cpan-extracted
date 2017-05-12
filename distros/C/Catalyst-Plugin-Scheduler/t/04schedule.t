#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use Storable qw/lock_store lock_retrieve/;

plan tests => 10;
use Catalyst::Test 'TestApp';

our $STATE = "$FindBin::Bin/lib/TestApp/scheduler.state";

TestApp->schedule(
    at    => '* * * * *',
    event => '/cron/every_minute',
);

TestApp->schedule(
    at    => '@hourly',
    event => \&every_hour,
);

# events with errors to test the error handling
TestApp->schedule(
    at    => '*/2 * * * *',
    event => '/cron/test_errors',
);

TestApp->schedule(
    at    => '0 * * * *',
    event => \&broken_event,
);

# hack the last event check to make all events execute immediately
my $state = { last_check => 0 };
lock_store $state, $STATE;

# test that all events execute, and that the error test doesn't break the app
{
    open STDERR, '>/dev/null';
    ok( my $res = request('http://localhost/'), 'request ok' );
    is( $res->content, 'default', 'response ok' );
    is( -e "$FindBin::Bin/lib/TestApp/every_minute.log", 1, 'every_minute executed ok' );
    unlink "$FindBin::Bin/lib/TestApp/every_minute.log";
    is( -e "$FindBin::Bin/lib/TestApp/every_hour.log", 1, 'every_hour executed ok' );
    unlink "$FindBin::Bin/lib/TestApp/every_hour.log";
}

# run again, the events should not execute
{
    ok( my $res = request('http://localhost/'), 'request ok' );
    is( -e "$FindBin::Bin/lib/TestApp/every_minute.log", undef, 'every_minute did not execute, ok' );
    unlink "$FindBin::Bin/lib/TestApp/every_minute.log";
    is( -e "$FindBin::Bin/lib/TestApp/every_hour.log", undef, 'every_hour did not execute, ok' );
    unlink "$FindBin::Bin/lib/TestApp/every_hour.log";
}

# jump back in time by 2 hours, make sure both events run
{
    my $state = lock_retrieve $STATE;
    $state->{last_check} -= 60 * 120;
    lock_store $state, $STATE;
    
    ok( my $res = request('http://localhost/'), 'request ok' );
    is( -e "$FindBin::Bin/lib/TestApp/every_minute.log", 1, 'every_minute executed ok' );
    unlink "$FindBin::Bin/lib/TestApp/every_minute.log";
    is( -e "$FindBin::Bin/lib/TestApp/every_hour.log", 1, 'every_hour executed ok' );
    unlink "$FindBin::Bin/lib/TestApp/every_hour.log";
}

###

sub every_hour {
    my $c = shift;
    
    # write out a file so the test knows we did something
    my $fh = IO::File->new( $c->path_to( 'every_hour.log' ), 'w' )
        or die "Unable to write log file: $!";
    close $fh;
}

sub broken_event {
    my $c = shift;
    
    die 'oops';
}
