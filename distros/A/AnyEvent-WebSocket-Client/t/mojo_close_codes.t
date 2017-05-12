use strict;
use warnings;
use utf8;
use AnyEvent::WebSocket::Client;
use Test::More;
BEGIN { plan skip_all => 'Requires EV' unless eval q{ use EV; 1 } }
BEGIN { plan skip_all => 'Requires Mojolicious 3.0' unless eval q{ use Mojolicious 3.0; 1 } }
BEGIN { plan skip_all => 'Requires Mojolicious::Lite' unless eval q{ use Mojolicious::Lite; 1 } }
use FindBin;
use lib $FindBin::Bin;
use testlib::Mojo;
use testlib::Server;

testlib::Server->set_timeout;

plan tests => 6;

app->log->level('fatal');

my $cv;

websocket '/close' => sub {
  my($self) = shift;
  $self->on(finish => sub {
    my ($ws, $code, $reason) = @_;
    $cv->send($code, $reason);
  });
};

my ($server, $port) =  testlib::Mojo->start_mojo(app => app());
my $client = AnyEvent::WebSocket::Client->new;

code_ok([],                 [1005, ''],         'empty list defaults to 1005');
code_ok([undef, undef],     [1005, ''] ,        'both undef');
code_ok([undef, 'error'],   [1005, 'error'] ,   'undef code with explicit reason');
code_ok([1003, undef],      [1003, ''] ,        'other code with undef reason');
code_ok([1000],             [1000, ''],         'normal close code');
code_ok([1000, 'a reason'], [1000, 'a reason'], 'normal close code with reason');

my $connection;
sub code_ok {
  $cv = AE::cv;
  my ($args, $check, $label) = @_;

  $client->connect("ws://127.0.0.1:$port/close")->cb( sub {
    $connection = eval { shift->recv };
    if($@) {
      warn('Could not connect: %s', $@);
      return;
    }
    else {
      $connection->close(@{$args});
    }
  });

  my @recv = $cv->recv;

  is_deeply \@recv, $check, $label;
}
