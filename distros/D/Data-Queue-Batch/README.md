# NAME

Data::Queue::Batch - FIFO data structure for "batching" items

# SYNOPSIS

    use Data::Queue::Batch;

    # Callback interface
    {
        my @batched_items;
        my $q = Data::Queue::Batch->new(
            batch_size => 3,
            callback => sub {
                push(@batched_items, [@_]);
            },
        );

        $q->push(1, 2, 3, 4, 5);
        [@batched_items]; # => is_deeply [ [1, 2, 3] ]

        $q->push(6, 7);
        [@batched_items]; # => is_deeply [ [1, 2, 3], [4, 5, 6] ]

        $q->flush;
        [@batched_items]; # => is_deeply [ [1, 2, 3], [4, 5, 6], [7] ]

        $q->push(8);
        undef $q; # automatically flush on destroy
        [@batched_items]; # => is_deeply [ [1, 2, 3], [4, 5, 6], [7], [8] ]
    }

    # Procedual interface
    {
        my $q = Data::Queue::Batch->new(batch_size => 3);
        $q->enqueue(1);
        $q->push(2); # alias for 'enqueue'

        $q->dequeue; # => undef
        $q->shift; # alias for 'dequeue';

        $q->size; # => 2

        $q->push(3); # the first batch gets filled, so you can dequeue items
        $q->shift; # => 1
        $q->shift; # => 2

        $q->clear;
        $q->size; # => 0
    }

# DESCRIPTION

This is a simple FIFO data structure library to dequeue items by configured batch size.

This will be usable for processing items **in batch**, like bulk insertion to the database, etc.

For clarification, imagine the following queue:

    <- head
    [ ooooo | ooo ]

This queue's `batch_size` is 5, and there are 8 items in the queue.
But you can see only first 5 items, and can't dequeue / peek last 3 items, because the second _batch_ hasn't been filled yet.

Then, push additional 3 items:

    <- head
    [ ooooo | ooooo | o ]

At this time, you can retrieve fist 10 items since the first and second _batch_es get filled.

Let's dequeue 2 items. After that, the queue can be described as the following:

    <- head
    [ ooo | ooooo | o ]

You can dequeue / peek the first 8 items, but the last element is still not available yet.

# METHOD

## new(%options)

Creates a new queue object.

Options are:

- `batch_size => $size || 100`

    The batch size for retrieving items. The enqueued items are placed in each _batch_ with the `batch_size` capacity. The items will never be available without having their batches filled.

- `callback =>\&cb || undef` 

    The callback subroutine which will be called when the first batch gets filled.
    When you use callback interface, you don't need dequeue manually.

    If the `callback` is set, `flush()` will be automarically called when the queue is destroyed.

## enqueue(@items)

## push(@items)

Enqueues the items into the queue.

## dequeue()

## shift()

Dequeues the first item from the queue, and returns it.

If the `callback` is set, you don't need to dequeue manually (but you can also do it).

## peek(n)

Returns the available `c` itmes from the head, but don't remove from the queue.

## clear()

Clears the queue. The callback won't be called.

## flush()

Dequeues all items remained in the last (unfilled) batch with calling callback, and returns dequeued items.

This will be gets called when the queue is destroyed and the callback is set.

## size()

Returns the total size of the queue.

This is the real size of the queue, i.e. it includes the number of the items whose batch is unfilled yet.

## available()

Returns the number of items which can be retrieved.

## batch\_size()

Getter for `batch_size` option argument.

# LICENSE

Copyright (C) Ichito Nagata.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Ichito Nagata <i.nagata110@gmail.com>
