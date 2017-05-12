use common::sense;

use List::Util;

use AnyEvent::Util;
use AnyEvent::Task::Server;
use AnyEvent::Task::Client;

use Test::More tests => 7;


## The point of this test is to ensure that client requests are queued as per
## the design. In order to simplify, we set max_workers to 1 so that at most
## one checkout will be active at any given time.



AnyEvent::Task::Server::fork_task_server(
  listen => ['unix/', '/tmp/anyevent-task-test.socket'],
  interface => sub {
                     return $$;
                   },
);



my $client = AnyEvent::Task::Client->new(
               connect => ['unix/', '/tmp/anyevent-task-test.socket'],
               max_workers => 1,
             );


my $cv = AE::cv;

my $pid;
my $counter = 0;

{
  $client->checkout->(sub {
    my ($checkout, $ret) = @_;

    is($counter, 0); $counter++;
    $pid = $ret;

    $checkout->(sub {
      my ($checkout, $ret) = @_;

      is($counter, 1); $counter++;
      is($pid, $ret);
    });

    undef $checkout; ## doesn't matter if checkout is released here or not: already a checkout ahead in the queue

    $client->checkout->(sub {
      my ($checkout, $ret) = @_;

      is($counter, 3); $counter++;
      is($pid, $ret);

      $cv->send;
    });

    1; ## so new checkout above is called in void context
  });

  $client->checkout->(sub {
    my ($checkout, $ret) = @_;

    is($counter, 2); $counter++;
    is($pid, $ret);
  });
}


$cv->recv;
