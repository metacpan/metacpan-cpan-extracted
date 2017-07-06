#!perl -w
use Test::More tests => 1;
BEGIN {
if( $^O !~ /mswin|darwin/i ) {
    if( ! $ENV{DISPLAY} ) {
        SKIP: {
            skip "Need a display for the tests", 1;
        };
        exit;
    };
};
}

use Prima;
use AnyEvent;
use Prima::Application;
use AnyEvent::Impl::Prima;

my $mw = Prima::MainWindow->new();

my $called;
my $t = AnyEvent->timer(
    cb => sub { $called++; $mw->close if $called > 1 },
    after => 4,
    interval => 1,
);

Prima->run;

is $called, 2, "We catch repeating timers";

done_testing;
