use strict;
use warnings;
use utf8;
use AnyEvent::WebSocket::Client;
use Test::More;
BEGIN { plan skip_all => 'Requires EV' unless eval q{ use EV; 1 } }
BEGIN { plan skip_all => 'Requires Mojolicious 3.0' unless eval q{ use Mojolicious 3.0; 1 } }
BEGIN { plan skip_all => 'Requires Mojolicious::Lite' unless eval q{ use Mojolicious::Lite; 1 } }
use Protocol::WebSocket;
use FindBin;
use lib $FindBin::Bin;
use testlib::Mojo;
use Encode qw(encode);
use testlib::Server;

plan tests => 3;

testlib::Server->set_timeout;

my @test_cases = (
  { send => { binary => "hoge"}, recv_exp => ["hoge", "is_binary"] },
  { send => { text   => "foobar"}, recv_exp => ["foobar", "is_text"] },
  { send => { binary => encode("utf8", "ＵＴＦー８") }, recv_exp => [encode("utf8", "ＵＴＦー８"), "is_binary"] },
  { send => { text   => encode("utf8", "ＵＴＦー８") }, recv_exp => [encode("utf8", "ＵＴＦー８"), "is_text"] },
);

app->log->level('fatal');

websocket '/data' => sub {
  my($self) = shift;
  $self->on(message => sub {
    my($self, $index) = @_;
    $self->send($test_cases[$index]{send});
  });
};

my ($server, $port) =  testlib::Mojo->start_mojo(app => app());

my $client = AnyEvent::WebSocket::Client->new;

my $connection = $client->connect("ws://127.0.0.1:$port/data")->recv;
isa_ok $connection, 'AnyEvent::WebSocket::Connection';

subtest 'on_next_data' => sub {
  my $cb_count = 0;
  for my $test_index (0 .. $#test_cases)
  {
    my $cv = AnyEvent->condvar;
    $connection->on(next_message => sub { $cb_count++; $cv->send(@_) });
    $connection->send($test_index);
    my($connection, $message) = $cv->recv;
    isa_ok $connection, 'AnyEvent::WebSocket::Connection';
    is $message->body, $test_cases[$test_index]->{recv_exp}->[0], "body = " . $message->body;
    my $method = $test_cases[$test_index]->{recv_exp}->[1];
    ok $message->$method, "\$message->$method is true";
    
  }
  is($cb_count, scalar(@test_cases), "callback count OK");
};

subtest 'on_each_data' => sub {
  my $cv;
  my $cb_count = 0;
  $connection->on(each_message => sub { $cb_count++; $cv->send(@_) });
  for my $test_index (0 .. $#test_cases)
  {
    $cv = AnyEvent->condvar;
    $connection->send($test_index);
    my($connection, $message) = $cv->recv;
    isa_ok $connection, 'AnyEvent::WebSocket::Connection';
    is $message->body, $test_cases[$test_index]->{recv_exp}->[0], "body = " . $message->body;
    my $method = $test_cases[$test_index]->{recv_exp}->[1];
    ok $message->$method, "\$message->$method is true";
  }
  is($cb_count, scalar(@test_cases), "callback count OK");
};
