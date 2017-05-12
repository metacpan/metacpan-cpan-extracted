NAME
    Coro::PriorityQueue

SYNOPSIS
        use Coro::PriorityQueue;
        use Coro;

        my $queue = Coro::PriorityQueue->new(10);

        my $producer = async {
            foreach my $i (1 .. 10) {
                $queue->insert($i);
            }

            $queue->shutdown;
        };

        my $consumer = async {
            while (1) {
                my $i = $queue->remove or last;
                printf("%d * 2 = %d\n", $i, $i * 2);
            }
        };

        $producer->join, $consumer->join;

DESCRIPTION
    Priority queues automatically order their contents according to the
    inserted item's priority. Calling code must ensure that their queue
    items are comparable via this strategy (e.g. by overloading the <=>
    operator).

    Underneath, this is implemented as a simple array heap, using
    Coro::Semaphore to control access.

METHODS
  new($max)
    Creates a new queue that can store $max items.

  insert($item)
    Inserts an item into the queue. Will block the thread until a slot is
    available if necessary. If the queue has been shut down, croaks.

    It is an error to insert undef into the queue.

  remove
    Removes and returns an item from the queue. Blocks until an item becomes
    available if necessary. If the queue is shutdown, returns undefined
    immediately.

  count
    Returns the number of items currently stored.

  is_empty
    Returns true if the queue is empty.

  is_full
    Returns true if the queue is full.

  shutdown
    Shuts down the queue, after which no items may be inserted. Items
    already in the queue can be pulled normally until empty, after which
    further calls to "remove" will return undefined.

AUTHOR
    Jeff Ober <jeffober@gmail.com>

