#!perl -w
use Test::More tests => 4;
BEGIN {
if( $^O !~ /mswin|darwin/i ) {
    if( ! $ENV{DISPLAY} ) {
        SKIP: {
            skip "Need a display for the tests", 4;
        };
        exit;
    };
};
}
use AnyEvent::Impl::Prima;
use AnyEvent;
use AnyEvent::HTTP;
use Prima;
use Prima::Application;

use Test::HTTP::LocalServer;

my $server = Test::HTTP::LocalServer->spawn();

my $mw = Prima::MainWindow->new();

use Data::Dumper;
my $res;

my $timer;
my $web_request;
my $answer;

my $start_request; $start_request = AnyEvent->timer(
    after => 2,
    cb => sub {
        $timer++;

        $web_request = http_get $server->url,
            sub {
                $answer = $_[1];
                $mw->close
            },
        ;
    },
);

my $timeout;
my $t = AnyEvent->timer(
    cb => sub { $timeout++; $mw->close },
    after => 10,
);

Prima->run;

pass "We finished our main loop";
isn't $answer, undef, "We got an HTTP answer";
is $timer, 1, "Our timer got called";
is $timeout, undef, "No timeout";

done_testing;
