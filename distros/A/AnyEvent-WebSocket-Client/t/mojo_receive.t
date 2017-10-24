use utf8;
use lib 't/lib';
use Test2::Require::NotWindows;
use Test2::Require::Module 'EV';
use Test2::Require::Module 'Mojolicious' => '3.0';
use Test2::Require::Module 'Mojolicious::Lite';
use Test2::Plugin::AnyEvent::Timeout;
use Test2::V0 -no_srand => 1;
use Test2::Tools::WebSocket::Mojo qw( start_mojo );
use AnyEvent::WebSocket::Client;
use Mojolicious::Lite;
use Protocol::WebSocket;
use Encode qw(encode);

# NOTE: The mojo_* tests are to test interoperability with a really
# good implementation that is also written in Perl.  Mojolicious
# tests should not be written for new features and to test bugs,
# unless they are also accompanied by a non-Mojolicious test as well!

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

my ($server, $port) =  start_mojo(app => app());

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

done_testing;
