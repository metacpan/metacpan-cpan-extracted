use common::sense;

use List::Util;

use AnyEvent::Util;
use AnyEvent::Task::Server;
use AnyEvent::Task::Client;

use Test::More tests => 4;


## The point of this test is to verify that workers are restarted
## after they handle max_checkouts checkouts, and that the unix
## socket isn't unlinked after the worker terminates due to
## max_checkouts.



AnyEvent::Task::Server::fork_task_server(
  listen => ['unix/', '/tmp/anyevent-task-test.socket'],
  interface => sub {
                     return $$;
                   },
);



my $client = AnyEvent::Task::Client->new(
               connect => ['unix/', '/tmp/anyevent-task-test.socket'],
               max_workers => 1,
               max_checkouts => 2,
             );


my $cv = AE::cv;

my $pid;

my $timeout_watcher = AE::timer 1.0, 0, sub {
  print STDERR "hanged, probably because socket was unlinked";
  exit;
};

{
  $client->checkout->(sub {
    my ($checkout, $ret) = @_;
    $pid = $ret;
  });

  $client->checkout->(sub {
    my ($checkout, $ret) = @_;
    ok($pid == $ret, "orig pid the same: $pid");
  });

  $client->checkout->(sub {
    my ($checkout, $ret) = @_;
    ok($pid != $ret, "new pid ($ret) is different");
    $cv->send;
  });
}


$cv->recv;

select undef, undef, undef, 0.1; # give worker chance to close

$cv = AE::cv;

$client->checkout->(sub {
  my ($checkout, $ret) = @_;
  ok(1, "got response 1");
});

$client->checkout->(sub {
  my ($checkout, $ret) = @_;
  ok(1, "got response 2");
  $cv->send;
});

$cv->recv;
