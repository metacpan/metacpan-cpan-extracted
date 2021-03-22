use lib 't/lib';
use Test2::Require::Module 'Capture::Tiny';
use Test2::Require::Module 'Test::Memory::Cycle';
use Test2::Require::Module 'Devel::Cycle';
use Test2::Plugin::EV;
use Test2::Plugin::AnyEvent::Timeout;
use Test2::V0 -no_srand => 1;
use Test2::Tools::WebSocket::Server qw( start_server );
use AnyEvent::WebSocket::Client;
use Capture::Tiny qw( capture_stderr );
use Test::Memory::Cycle;

my $finished = 0;
my $done1 = AnyEvent->condvar;
my $done2 = AnyEvent->condvar;

my $uri = start_server(
  message => sub {
    my $opt = { @_ };

    return if !$opt->{frame}->is_text && !$opt->{frame}->is_binary;

    $opt->{hdl}->push_write($opt->{frame}->new(buffer => $opt->{message}, max_payload_size => 0 )->to_bytes);

  },
  end => sub {
    $finished = 1;
    $done1->send;
  },
);

my $client = AnyEvent::WebSocket::Client->new;
my $connection = $client->connect($uri)->recv;

$connection->on(each_message => sub { $done2->send });

isa_ok $connection, 'AnyEvent::WebSocket::Connection';

is $finished, 0, 'finished = 0';

$connection->send('foo');

is $finished, 0, 'finished = 0';

note capture_stderr { memory_cycle_ok $connection };

$done2->recv;

$connection->close;

note capture_stderr { memory_cycle_ok $connection };

undef $connection;

$done1->recv;

is $finished, 1, 'finished = 1';

done_testing;
