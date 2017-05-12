use common::sense;

use List::Util;
use POSIX;

use Callback::Frame;

use AnyEvent::Util;
use AnyEvent::Task::Server;
use AnyEvent::Task::Client;

use Test::More tests => 4;


## The point of this test is to ensure that when a worker connection dies
## suddenly, ie with POSIX::_exit(), an appropriate error is promptly raised
## in the callback's dynamic environment. This test also verifies that
## fatal errors like losing a worker connection put a checkout into
## a permanent error state that will always return the same fatal
## error message.



AnyEvent::Task::Server::fork_task_server(
  listen => ['unix/', '/tmp/anyevent-task-test.socket'],
  interface => sub {
                     select undef, undef, undef, 0.1;
                     POSIX::_exit(1);
                     die "shouldn't get here";
                   },
);


my $client = AnyEvent::Task::Client->new(
               connect => ['unix/', '/tmp/anyevent-task-test.socket'],
             );


my $cv = AE::cv;

{
  my $checkout = $client->checkout( timeout => 1, );

  $checkout->(frame(code => sub {
    die "checkout was serviced?";
  }, catch => sub {
    my $err = $@;
    ok(1, "error hit");
    ok($err !~ /timed out after/, "no timed out err");
    like($err, qr/worker connection suddenly died/, "sudden death err");

    $checkout->(frame(code => sub {
      die "shouldn't get here";
    }, catch => sub {
      my $err = $@;

      like($err, qr/worker connection suddenly died/, "got same fatal error after calling checkout again");

      $cv->send;
    }));
  }));
}

$cv->recv;
