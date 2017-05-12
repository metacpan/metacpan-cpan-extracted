use common::sense;

use List::Util;

use Callback::Frame;

use AnyEvent::Util;
use AnyEvent::Task::Server;
use AnyEvent::Task::Client;

use Test::More tests => 2;


## The point of this test is to ensure that checkouts are timed out
## when the worker process takes too long.


AnyEvent::Task::Server::fork_task_server(
  listen => ['unix/', '/tmp/anyevent-task-test.socket'],
  interface => sub {
                     select undef, undef, undef, 0.4;
                     die "shouldn't get here";
                   },
);


my $client = AnyEvent::Task::Client->new(
               connect => ['unix/', '/tmp/anyevent-task-test.socket'],
             );


my $cv = AE::cv;

{
  my $checkout = $client->checkout( timeout => 0.2, );

  $checkout->(frame(code => sub {
    die "checkout was serviced?";
  }, catch => sub {
    my $err = $@;
    print "## error: $err\n";
    ok(1, "timeout hit");
    ok($err =~ /timed out after/, 'correct err msg');
    $cv->send;
  }));
}

$cv->recv;
