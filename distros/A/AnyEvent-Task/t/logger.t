use common::sense;

use List::Util;

use Callback::Frame;

use AnyEvent::Util;
use AnyEvent::Task::Server;
use AnyEvent::Task::Client;
use AnyEvent::Task::Logger;

use Test::More tests => 14;


## The point of this test is to verify Log::Defer integration.
## If log_defer_object is passed in when creating a checkout:
##   1) The server can add log messages, timers, data, etc to
##      this object by using the AnyEvent::Task::Logger::logger
##   2) Every time a request is placed onto a checkout, a timer
##      is started in this object and it is ended once the
##      request is fulfilled.



AnyEvent::Task::Server::fork_task_server(
  listen => ['unix/', '/tmp/anyevent-task-test.socket'],
  interface => { normal =>
                   sub {
                     logger->info("hello from", $$);
                     logger->timer("junk");
                     1;
                   },
                 error =>
                   sub {
                     logger->warn("something weird happened");
                     die "uh oh";
                   },
                 sleep =>
                   sub { select undef,undef,undef,shift; },
               },
);



my $client = AnyEvent::Task::Client->new(
               connect => ['unix/', '/tmp/anyevent-task-test.socket'],
             );


my $cv = AE::cv;


my $log_defer_object = Log::Defer->new(sub {
  my $msg = shift;

  is($msg->{logs}->[0]->[2], 'hello from', 'message from client');
  is($msg->{logs}->[1]->[2], 'hello from', 'message from worker');
  isnt($msg->{logs}->[0]->[3], $msg->{logs}->[1]->[3], 'pids are different');
  is($msg->{logs}->[2]->[2], 'after', 'order of msgs ok');
  is($msg->{logs}->[3]->[2], 'something weird happened', 'log messages transfered even on error');

  is(@{$msg->{timers}}, 5, 'right number of timers');
  is($msg->{timers}->[0]->[0], 'normal', 'normal is timer 1');
  is($msg->{timers}->[1]->[0], 'junk', 'junk is timer 2');
  is($msg->{timers}->[2]->[0], 'sleep', 'sleep is timer 3');
  is($msg->{timers}->[3]->[0], 'sleep', 'sleep is timer 4');
  is($msg->{timers}->[4]->[0], 'error', 'error is timer 5');
});

$log_defer_object->info("hello from", $$);

$client->checkout(log_defer_object => $log_defer_object)->normal(sub {
  my ($checkout, $ret) = @_;

  $log_defer_object->info("after");

  $checkout->sleep(0.1, sub {});
  $checkout->sleep(0.1, sub {});

  $checkout->error(frame(code => sub {
    die "error not thrown?";
  }, catch => sub {
    ok(1, 'error caught');
    $cv->send;
  }));
});


$cv->recv;


$cv = AE::cv;

$log_defer_object = Log::Defer->new(sub {
  my $msg = shift;

  is($msg->{timers}->[0]->[0], '->()', "didn't leak first arg when called as code ref");
});

$client->checkout(log_defer_object => $log_defer_object)->('first arg', frame(code => sub {
  die "error not thrown by calling interface as a sub?";
}, catch => sub {
  ok(1, 'error caught');
  $cv->send;
}));

$cv->recv;
