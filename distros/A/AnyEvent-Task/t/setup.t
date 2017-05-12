use common::sense;

use List::Util;

use Callback::Frame;

use AnyEvent::Util;
use AnyEvent::Task::Server;
use AnyEvent::Task::Client;

use Test::More tests => 2;


## The point of this test is to verify that the setup feature can
## initialize a worker's environment before requests are handled,
## and that this initialization only runs once per worker process.


my $counter;

AnyEvent::Task::Server::fork_task_server(
  listen => ['unix/', '/tmp/anyevent-task-test.socket'],
  setup => sub {
             $counter = 100;
           },
  interface => sub {
                 $counter++;
                 return $counter;
               },
);



my $client = AnyEvent::Task::Client->new(
               connect => ['unix/', '/tmp/anyevent-task-test.socket'],
               max_workers => 1,
             );


my $cv = AE::cv;

{
  $client->checkout->(sub {
    my ($checkout, $res) = @_;

    ok($res == 101);

    $cv->send;
  });
}

$cv->recv;


$cv = AE::cv;

{
  $client->checkout->(sub {
    my ($checkout, $res) = @_;

    ok($res == 102);

    $cv->send;
  });
}

$cv->recv;
