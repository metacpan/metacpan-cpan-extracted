use common::sense;

use List::Util;
use POSIX;

use Callback::Frame;

use AnyEvent::Util;
use AnyEvent::Task::Server;
use AnyEvent::Task::Client;

use Test::More tests => 5;


## The point of this test is to verify that fatal errors cut off
## the worker and permanently disable the checkout. If methods are
## called again on the checkout they will continue to throw the
## fatal error.



AnyEvent::Task::Server::fork_task_server(
  listen => ['unix/', '/tmp/anyevent-task-test.socket'],
  interface => {
                 sleep_die => sub {
                                select undef, undef, undef, 1;
                                die "shouldn't get here";
                              },
                 get_pid => sub { $$ },
               },
);


my $client = AnyEvent::Task::Client->new(
               connect => ['unix/', '/tmp/anyevent-task-test.socket'],
             );


my $cv = AE::cv;

my $checkout = $client->checkout( timeout => 1, );

$checkout->sleep_die(frame(code => sub {
  die "checkout was serviced?";
}, catch => sub {
  my $err = $@;
  ok(1, "error hit");
  like($err, qr/manual request abort/, "manual request abort err");
  ok($err !~ /timed out after/, "no timed out err");
  ok($err !~ /hung worker/, "no hung worker err");

  $checkout->get_pid(frame(code => sub {
    die "shouldn't get here";
  }, catch => sub {
    my $err = $@;

    like($err, qr/manual request abort/, "continue to get manual abort error because error was fatal");
    $cv->send;
  }));

}));

$checkout->throw_fatal_error("manual request abort");

$cv->recv;
