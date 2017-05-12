use strict;
use warnings;
use Test::More 0.98;

use Data::Queue::Batch;

subtest 'basic' => sub {
    my $q = Data::Queue::Batch->new(batch_size => 3);

    $q->push(1, 2);
    is $q->shift, undef, "cannot dequeue anything from the queue which doesn't reach it's batch size";
    is $q->size, 2;
    
    $q->push(3);
    is_deeply [ $q->shift, $q->shift, $q->shift ], [1, 2, 3], 
        "can dequeue first 3 items from the queue since once the queue reached it's batch size";

    is $q->shift, undef, "the queue is empty";
    is $q->size, 0;
};

subtest 'items are managed in each batch' => sub {
    my $q = Data::Queue::Batch->new(batch_size => 3);

    $q->push(1, 2, 3);

    is $q->shift, 1;
    is $q->size, 2;

    $q->push(4);
    is $q->size, 3;

    is $q->shift, 2;
    is $q->size, 2;

    is $q->shift, 3;
    is $q->size, 1;

    is $q->shift, undef, "4 is not dequeued because the 'second' batch has not been filled yet";
    is $q->size, 1;

    $q->push(5);
    is $q->shift, undef, "yet..";

    $q->push(6);
    is $q->shift, 4, "filled!";
};

subtest 'flush' => sub {
    my $q = Data::Queue::Batch->new(batch_size => 10000);

    $q->push(1..3);
    my @flushed = $q->flush;
    is_deeply \@flushed, [1 .. 3], "forcely flush unfilled batches";
    is $q->size, 0;
};

subtest 'peek' => sub {
    my $q = Data::Queue::Batch->new(batch_size => 3);

    $q->push(1..5);
    is $q->size, 5;
    is_deeply [ $q->peek(1) ], [1];
    is_deeply [ $q->peek(5) ], [1, 2, 3];

    $q->push(6);
    is $q->size, 6;
    is_deeply [ $q->peek(5) ], [1, 2, 3, 4, 5];

    $q->push(7..8);
    $q->shift;
    $q->shift;
    $q->shift;
    is $q->size, 5; # (4..8)
    is_deeply [ $q->peek(5) ], [4, 5, 6], '7 and 8 has not been marked';
};

done_testing;

