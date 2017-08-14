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

websocket '/count/:num' => sub {
  my($self) = shift;

  my $max = $self->param('num');
  my $counter = 1;
  
  $self->on(message => sub {
   my($self, $payload) = @_;
     note "send $counter";
     $self->send($counter++);
     if($counter >= $max)
     {
       $self->finish;
     }
  });
};

my ($server, $port) = start_mojo(app => app());

my $client = AnyEvent::WebSocket::Client->new;

my $connection = $client->connect("ws://127.0.0.1:$port/count/10")->recv;
isa_ok $connection, 'AnyEvent::WebSocket::Connection';

my $done = AnyEvent->condvar;

$connection->send('ping');

my $last;

$connection->on(each_message => sub {
  my $message = pop->body;
  note "recv $message";
  $connection->send('ping');
  $last = $message;
});

$connection->on(finish => sub {
  $done->send(1);
});

is $done->recv, '1', 'friendly disconnect';

is $last, 9, 'last = 9';

done_testing;
