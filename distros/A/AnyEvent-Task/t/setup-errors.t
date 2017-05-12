use common::sense;

use List::Util;

use Callback::Frame;

use AnyEvent::Util;
use AnyEvent::Task::Server;
use AnyEvent::Task::Client;

use Test::More tests => 2;


## The point of this test is to verify that exceptions thrown in
## setup callbacks are propagated to the client. It also validates
## that by default workers are restarted on setup errors.


my $attempt = 0;

AnyEvent::Task::Server::fork_task_server(
  listen => ['unix/', '/tmp/anyevent-task-test.socket'],
  setup => sub {
             $attempt++;
             die "SETUP EXCEPTION $attempt";
           },
  interface => sub {
                 die "INTERFACE EXCEPTION (shouldn't happen)";
               },
);



my $client = AnyEvent::Task::Client->new(
               connect => ['unix/', '/tmp/anyevent-task-test.socket'],
               max_workers => 1,
             );


my $cv = AE::cv;

{
  $client->checkout->(frame(code => sub {
    die "should never get here";
  }, catch => sub {
    my $err = $@;

    like($err, qr/setup exception: SETUP EXCEPTION 1/);

    $cv->send;
  }));
}


$cv->recv;


$cv = AE::cv;

{
  $client->checkout->(frame(code => sub {
    die "should never get here";
  }, catch => sub {
    my $err = $@;

    like($err, qr/setup exception: SETUP EXCEPTION 1/);

    $cv->send;
  }));
}


$cv->recv;
