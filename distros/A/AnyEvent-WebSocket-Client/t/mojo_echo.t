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

# NOTE: The mojo_* tests are to test interoperability with a really
# good implementation that is also written in Perl.  Mojolicious
# tests should not be written for new features and to test bugs,
# unless they are also accompanied by a non-Mojolicious test as well!

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

my ($server, $port) =  start_mojo(app => app());

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

done_testing;
