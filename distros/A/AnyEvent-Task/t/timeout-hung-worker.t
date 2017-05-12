use common::sense;

use List::Util;

use Callback::Frame;

use AnyEvent::Util;
use AnyEvent::Task::Server;
use AnyEvent::Task::Client;

use Test::More tests => 3;


## The point of this test is to ensure that if a worker is "hung" on some
## operation, it will eventually die off. Since this is implemented with
## SIGALRM/alarm we have to hang for at least a second which makes this
## test slow :(



AnyEvent::Task::Server::fork_task_server(
  listen => ['unix/', '/tmp/anyevent-task-test.socket'],
  interface => sub {
                     select undef, undef, undef, 3; # can't use sleep() because sleep might use alarm
                     die "shouldn't get here";
                   },
  hung_worker_timeout => 1, ## can't be a float because we use alarm()
);


my $client = AnyEvent::Task::Client->new(
               connect => ['unix/', '/tmp/anyevent-task-test.socket'],
             );


my $cv = AE::cv;

{
  my $checkout = $client->checkout( timeout => 2, );

  $checkout->(frame(code => sub {
    die "checkout was serviced?";
  }, catch => sub {
    my $err = $@;
    diag("Hung worker error: $err");
    ok(1, "error hit");
    ok($err !~ /timed out after/, "no timed out err");
    ok($err =~ /worker connection suddenly/, "hung worker err");
    $cv->send;
  }));
}

$cv->recv;
