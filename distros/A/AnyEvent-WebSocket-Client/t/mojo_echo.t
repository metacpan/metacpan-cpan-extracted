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
use testlib::Server;

testlib::Server->set_timeout;

plan tests => 8;

app->log->level('fatal');

websocket '/echo' => sub {
  my($self) = shift;
  $self->on(message => sub {
    my($self, $payload) = @_;
    $self->send($payload);
    if($payload eq "quit")
    {
      $self->finish;
    }
  });
};

my ($server, $port) =  testlib::Mojo->start_mojo(app => app());

my $client = AnyEvent::WebSocket::Client->new;

my $connection = $client->connect("ws://127.0.0.1:$port/echo")->recv;
isa_ok $connection, 'AnyEvent::WebSocket::Connection';

my $quit_cv = AnyEvent->condvar;
$connection->on(finish => sub {
  $quit_cv->send("finished");
});

for my $testcase (
  {label => "single character", data => "a"},
  {label => "5k bytes", data => "a" x 5000},
  {label => "empty", data => ""},
  {label => "0", data => 0},
  {label => "utf8 charaters", data => 'ＵＴＦ８ ＷＩＤＥ ＣＨＡＲＡＣＴＥＲＳ'},
  {label => "quit", data => "quit"},
)
{
  my $cv = AnyEvent->condvar;
  $connection->on(next_message => sub {
    my $message = pop->decoded_body;
    $cv->send($message);
  });
  $connection->send($testcase->{data});
  is $cv->recv, $testcase->{data}, "$testcase->{label}: echo succeeds";
}

is $quit_cv->recv, "finished", "friendly disconnect";

