use strict;
use warnings;

use Async::Queue;

## create a queue object with concurrency 2
my $q = Async::Queue->new(
    concurrency => 2, worker => sub {
        my ($task, $callback) = @_;
        print "hello $task->{name}\n";
        $callback->();
    }
);

## assign a callback
$q->drain(sub {
    print "all items have been processed\n";
});

## add some items to the queue
$q->push({name => 'foo'}, sub {
    print "finished processing foo\n";
});
$q->push({name => 'bar'}, sub {
    print "finished processing bar\n";
});




