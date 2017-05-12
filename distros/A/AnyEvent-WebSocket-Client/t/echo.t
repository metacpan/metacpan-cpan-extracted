use strict;
use warnings;
use utf8;
BEGIN { eval q{ use EV } }
use Protocol::WebSocket;
use AnyEvent::WebSocket::Client;
use AnyEvent::WebSocket::Message;
use Test::More tests => 4;
use FindBin ();
use lib $FindBin::Bin;
use testlib::Server;

testlib::Server->set_timeout;

my $uri = testlib::Server->start_echo;

my $connection = AnyEvent::WebSocket::Client->new->connect($uri)->recv;
isa_ok $connection, 'AnyEvent::WebSocket::Connection';

my $quit_cv = AnyEvent->condvar;
$connection->on(finish => sub {
  $quit_cv->send("finished");
});

my @test_data = (
  {label => "single character", data => "a"},
  {label => "5k bytes", data => "a" x 5000},
  {label => "empty", data => ""},
  {label => "0", data => 0},
  {label => "utf8 charaters", data => 'ＵＴＦ８ ＷＩＤＥ ＣＨＡＲＡＣＴＥＲＳ'},
);

subtest legacy => sub {
  foreach my $testcase (@test_data) {
    my $cv = AnyEvent->condvar;
    $connection->on(next_message => sub {
      my $message = pop->decoded_body;
      $cv->send($message);
    });
    $connection->send($testcase->{data});
    is $cv->recv, $testcase->{data}, "$testcase->{label}: echo succeeds";
  }
};

subtest new => sub {
  foreach my $testcase (@test_data) {
    my $cv = AnyEvent->condvar;
    $connection->on(next_message => sub {
      my ($connection, $message) = @_;
      $cv->send($message->decoded_body);
    });
    $connection->send(AnyEvent::WebSocket::Message->new( body => $testcase->{data}, opcode => 1));
    is $cv->recv, $testcase->{data}, "$testcase->{label}: echo succeeds";
  }
};

$connection->send('quit');

is $quit_cv->recv, "finished", "friendly disconnect";


