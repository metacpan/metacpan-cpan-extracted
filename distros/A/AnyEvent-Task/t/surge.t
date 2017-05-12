use common::sense;

use List::Util;

use AnyEvent::Task::Server;
use AnyEvent::Task::Client;

use Test::More tests => 102;


## The point of this test is to ensure that even if we make many more
## checkouts than there are max workers, all of them are eventually
## still serviced.



AnyEvent::Task::Server::fork_task_server(
  listen => ['unix/', '/tmp/anyevent-task-test.socket'],
  interface => sub {
                 my $i = shift;
                 return $i;
               },
);



my $client = AnyEvent::Task::Client->new(
               connect => ['unix/', '/tmp/anyevent-task-test.socket'],
               max_workers => 5,
             );


my $cv = AE::cv;

my $counter = 0;

for my $i (1 .. 100) {
  $client->checkout->($i, sub {
    my ($checkout, $ret) = @_;

    is($ret, $i);
    $counter++;

    $cv->send if $counter == 100;
  });
}

is($counter, 0);

$cv->recv;

is($counter, 100);
