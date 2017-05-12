use common::sense;

use List::Util;
use POSIX;

use Callback::Frame;

use AnyEvent::Util;
use AnyEvent::Task::Server;
use AnyEvent::Task::Client;

use Test::More tests => 3;


## The point of this test is to verify that method calls can queue
## up on a checkout and that if any errors are thrown by one of
## the queued methods, then all the other method calls are removed
## from the checkout's queue.



AnyEvent::Task::Server::fork_task_server(
  listen => ['unix/', '/tmp/anyevent-task-test.socket'],
  interface => {
                 die => sub { die "ouch"; },
                 success => sub { 1 },
               },
);


my $client = AnyEvent::Task::Client->new(
               connect => ['unix/', '/tmp/anyevent-task-test.socket'],
             );


my $cv = AE::cv;

my $timeout_watcher = AE::timer 0.5, 0, sub {
  $cv->send;
};

my $num_exceptions_caught = 0;

frame(code => sub {
  my $checkout = $client->checkout;

  $checkout->success(sub { ok(1, "first in checkout queue") });
  $checkout->success(sub { ok(1, "second in checkout queue") });

  $checkout->die(sub { die "exception should have been caught instead of calling this" });

  $checkout->success(sub { die "this should have been removed from the queue" });
  $checkout->success(sub { die "should have been removed" });
}, catch => sub {
  $num_exceptions_caught++;
  die "multiple exceptions thrown" unless $num_exceptions_caught == 1;
  ok(1, "caught exception");
})->();

$cv->recv;
