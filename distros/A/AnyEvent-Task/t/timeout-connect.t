use common::sense;

use List::Util;

use Callback::Frame;

use AnyEvent::Util;
use AnyEvent::Task::Server;
use AnyEvent::Task::Client;

use Test::More tests => 1;


## The point of this test is to ensure that checkouts are timed out
## when the client is unable to connect to the server at all.




my $client = AnyEvent::Task::Client->new(
               connect => ['unix/', '/tmp/anyevent-task-test-non-existent.socket'],
             );


my $cv = AE::cv;

{
  my $checkout = $client->checkout( timeout => 0.2, );

  $checkout->(frame(code => sub {
    ok(0, "checkout was serviced?");
  }, catch => sub {
    print "## error: $@\n";
    ok(1, "timeout hit");
    $cv->send;
  }));
}

$cv->recv;
