# NAME

Acme::Parataxis - Lightweight Cooperative Fibers

# SYNOPSIS

```perl
use v5.40;
use Acme::Parataxis qw[:all];
$|++;
async {
    say 'Main task started';
    my $f1 = fiber {
        say '  Task 1: Sleeping...';
        await_sleep(1000);
        say '  Task 1: Waking up';
        return 'Coffee!';
    };
    my $f2 = fiber {
        say '  Task 2: Calculating... (simulated CPU work)';
        my $sum = 0;
        for ( 1 .. 100 ) {
            $sum += $_;
            yield;    # yield control back to the scheduler
        }
        say '  Task 2: Complete. Will return ' . $sum;
        return $sum;
    };

    # await works on fibers and futures
    say 'Result 1: ' . await($f1);
    say 'Result 2: ' . await($f2);
};
# Output:
# Main task started
#   Task 1: Sleeping...
#   Task 2: Calculating... (simulated CPU work)
#   Task 2: Complete. Will return 5050
#   Task 1: Waking up
# Result 1: Coffee!
# Result 2: 5050
```

# DESCRIPTION

`Acme::Parataxis` brings stackful cooperative multitasking (green threads or fibers) and native thread-pool offloading
to Perl. It combines cooperative multitasking (fibers) with a preemptive native thread pool.

All Perl code runs within a fiber: a user-space thread of execution with its own C-level execution context and
independent Perl interpreter stacks (argument, mark, scope, save, and mortal stacks). Unlike preemptive OS threads,
fibers are cooperatively scheduled: a fiber runs until it yields or pauses for a blocking operation. Because scheduling
is deterministic, mutable state shared across fibers requires no mutex locks unless an operation suspends across a
yield boundary.

When a fiber encounters a blocking task such as sleeping or waiting on a file descriptor, it will not stall the Perl
interpreter. Instead, the calling fiber is suspended, the blocking wait is offloaded to a background OS worker thread
in a native C thread pool (or an attached event loop), and the scheduler resumes other runnable fibers. Once the
background operation completes, the parked fiber is re-enqueued and resumes with its result.

The core exports the scheduler interface (`async`, `run`), fiber lifecycle tools (`fiber`, `spawn`, `yield`,
`await`), async I/O primitives (`await_sleep`, `await_read`, `await_write`), structured concurrency (`nursery`),
and cooperative cancellation (`with_timeout`, `with_cancel`).

Higher-level abstractions are separated into dedicated companion classes:

- [Acme::Parataxis::Actor](https://metacpan.org/pod/Acme%3A%3AParataxis%3A%3AActor) - Isolated state behind a private fiber with an incoming mailbox.
- [Acme::Parataxis::Channel](https://metacpan.org/pod/Acme%3A%3AParataxis%3A%3AChannel) - Bounded CSP message queues with backpressure and multiplexed `select`.
- [Acme::Parataxis::Blocking](https://metacpan.org/pod/Acme%3A%3AParataxis%3A%3ABlocking) - Offload heavy CPU work to cloned interpreters or forked processes.
- [Acme::Parataxis::Future](https://metacpan.org/pod/Acme%3A%3AParataxis%3A%3AFuture) - Single-assignment asynchronous values and completion hooks.
- [Acme::Parataxis::Stream](https://metacpan.org/pod/Acme%3A%3AParataxis%3A%3AStream) - FRP-style streaming pipelines over bounded channels.
- [Acme::Parataxis::Sync](https://metacpan.org/pod/Acme%3A%3AParataxis%3A%3ASync) - Mutexes, read/write locks, wait groups, barriers, and initializers.
- [Acme::Parataxis::TVar](https://metacpan.org/pod/Acme%3A%3AParataxis%3A%3ATVar) - Software Transactional Memory (STM) with automatic retry on conflict.
- [Acme::Parataxis::Compat](https://metacpan.org/pod/Acme%3A%3AParataxis%3A%3ACompat) - Gevent-style transparent unblocking for legacy `sleep` and `read` calls.

This project was greatly inspired by the concurrency system for the [Wren](https://wren.io/concurrency.html)
programming language and my own curiosity; I wanted to see how hard it would be to fiddle with perl's core from an FFI
and nothing requires more fiddling than picking up the full context and swapping it around at runtime.

# FUNCTIONS

Importable individually or with the `:all` tag.

## `async { ... }`

```
async {
    # scheduler starts, executes block as the root fiber, and stops when finished
};
```

Convenience wrapper around `run()`. Executes the provided code block as the initial root fiber of a new scheduler
session and stops the scheduler once the block returns or dies.

## `fiber { ... }`

```perl
my $f = fiber {
    my $val = do_work();
    return $val;
};
```

Creates and schedules a new fiber. An alias for `spawn()`. Returns the `Acme::Parataxis` fiber object, which
implements the Future interface (`await`, `result`, `error`, `on_ready`).

## `await( $target )`

```perl
my $val = await($fiber_or_future);
```

Suspends the current fiber until `$target` completes. `$target` may be an `Acme::Parataxis` fiber, an
[Acme::Parataxis::Future](https://metacpan.org/pod/Acme%3A%3AParataxis%3A%3AFuture), or an [Acme::Parataxis::Monitor](https://metacpan.org/pod/Acme%3A%3AParataxis%3A%3AMonitor). Returns the resolution value or rethrows the target's
death error in the caller.

## `yield( [@args] )`

```perl
yield();
my $reply = yield('hello');
```

Suspends the current fiber and returns control to the scheduler. If `@args` are passed, they are delivered to the
context that next calls or resumes this fiber.

## `await_sleep( $ms )`

```
await_sleep(250);    # sleep 250 milliseconds
```

Cooperatively suspends the current fiber for `$ms` milliseconds. The delay is handed to the native thread pool or
attached driver, allowing other fibers to execute.

## `await_read( $fh, [$timeout_ms = 5000] )`

```perl
my $ready = await_read( $socket, 2000 );
```

Suspends the current fiber until `$fh` is ready to read or the timeout expires. Returns `1` on readiness, `-1` on
timeout or unwatchable handle.

## `await_write( $fh, [$timeout_ms = 5000] )`

```perl
my $ready = await_write( $socket, 2000 );
```

Suspends the current fiber until `$fh` is ready to accept writes. Returns `1` on readiness, `-1` on timeout.

## `with_timeout( $ms, [$token,] $code )`

```perl
my $val = with_timeout( 1000, sub {
    return fetch_data();
} );
```

Runs `$code` under a strict deadline. If execution does not complete within `$ms` milliseconds, any parked wait
aborts and throws [Acme::Parataxis::Error::Timeout](https://metacpan.org/pod/Acme%3A%3AParataxis%3A%3AError%3A%3ATimeout). If an optional [Acme::Parataxis::CancellationToken](https://metacpan.org/pod/Acme%3A%3AParataxis%3A%3ACancellationToken) is provided,
cancelling the token interrupts the block early with [Acme::Parataxis::Error::Cancelled](https://metacpan.org/pod/Acme%3A%3AParataxis%3A%3AError%3A%3ACancelled).

## `with_cancel( sub ($token) { ... } )`

```perl
my ($token, @res) = with_cancel( sub ($t) {
    fiber { await_sleep(100); $t->cancel };
    await_sleep(10_000);
} );
```

Executes `$code` within a scoped cancellation context. The block receives a fresh `CancellationToken`. Any wait
parked inside the scope is interrupted if the token cancels. In list context, returns the token followed by the block's
return values; in scalar or void context, returns the token alone.

## `nursery( sub ($n) { ... } )`

```perl
nursery( sub ($n) {
    $n->spawn( sub { worker_one() } );
    $n->spawn( sub { worker_two() } );
} );
```

Structured concurrency scope. Runs the block, joins every child fiber spawned through `$n->spawn`, and guarantees
that all children finish before `nursery()` returns. If any child dies, its siblings are immediately cancelled, the
entire nursery drains, and the primary failure is rethrown as an [Acme::Parataxis::Error::Nursery](https://metacpan.org/pod/Acme%3A%3AParataxis%3A%3AError%3A%3ANursery).

## `wait_all( @futures )`

```perl
my $aggregate = wait_all( $f1, $f2 );
my $results   = await($aggregate);    # [ $res1, $res2 ]
```

Takes a list of futures/fibers and returns a new Future that resolves with an arrayref of results once every input has
succeeded. If any input fails, the aggregate fails fast with that first error.

## `wait_any( @futures )`

```perl
my $winner = await( wait_any( $f1, $f2 ) );
```

Returns a Future that completes as soon as the first input future settles (whether by success or failure), adopting
that winner's outcome.

## `pmap( \%opts, $code, @items )`

```perl
my @results = pmap( { concurrency => 4 }, sub ($item) {
    return process_item($item);
}, @items );
```

Maps a subroutine over a list of items using a pool of concurrent fibers bounded by `concurrency` (default: one fiber
per item). Preserves input ordering. If any worker throws, in-flight fibers are cancelled and the error is rethrown.

# SCHEDULER & RUNTIME METHODS

## `Acme::Parataxis->run( $code, [%opts] )`

```perl
my $status = Acme::Parataxis->run(
    code        => sub { ... },
    virtual     => 0,
    on_shutdown => 1
);
```

Starts the scheduler event loop. Options include:

- `virtual => 1`

    Activates deterministic mock time. Timed waits (`await_sleep`, timeouts, intervals) do not advance real clocks; time
    is stepped explicitly via `Acme::Parataxis->advance($ms)`.

- `on_shutdown => 1 | $coderef | $token`

    Installs graceful shutdown handlers for `SIGINT` and `SIGTERM`. The first signal cancels the run's root token,
    unwinding active fibers. Returns exit code `130` (SIGINT) or `143` (SIGTERM).

## `Acme::Parataxis->stop()`

Signals the scheduler to exit its loop once currently runnable fibers yield.

## `Acme::Parataxis->current_fid()`

Returns the numeric fiber ID of the currently executing fiber, or `-1` from top-level unmanaged code.

## `Acme::Parataxis->by_id( $fid )`

Returns the live `Acme::Parataxis` fiber object for the given ID, or `undef` if completed or nonexistent.

## `Acme::Parataxis->attach_loop( $loop )`

Attaches an external event loop driver (such as `Mojo::IOLoop` or `IO::Async::Loop`), delegating descriptor readiness
and timer execution to that loop rather than the native C worker pool.

## `Acme::Parataxis->detach_loop()`

Detaches the current event loop driver and reverts to the built-in native thread pool.

# Behavior Notes

- Cooperative execution

    A fiber running a tight synchronous CPU loop (e.g. `1 while 1`) blocks the entire OS thread. Call `yield`
    periodically to let other fibers run, or offload heavy computation with [Acme::Parataxis::Blocking](https://metacpan.org/pod/Acme%3A%3AParataxis%3A%3ABlocking).

- Stack safety

    Each fiber receives an independent C-level and Perl-level stack. C-level stack boundaries are protected by guard pages
    allocated via `mmap`. Exceeding stack limits aborts with a diagnostic error rather than silently corrupting memory.

- Exception delivery

    When a fiber dies, its exception is retained in its error slot. Awaiting that fiber immediately rethrows the exception
    in the awaiting fiber. If an uncaught exception escapes the root fiber of a scheduler run, it propagates out of
    `run()`.

# SEE ALSO

All the examples in `eg/`.

[Acme::Parataxis::Actor](https://metacpan.org/pod/Acme%3A%3AParataxis%3A%3AActor), [Acme::Parataxis::Blocking](https://metacpan.org/pod/Acme%3A%3AParataxis%3A%3ABlocking), [Acme::Parataxis::Channel](https://metacpan.org/pod/Acme%3A%3AParataxis%3A%3AChannel),
[Acme::Parataxis::CancellationToken](https://metacpan.org/pod/Acme%3A%3AParataxis%3A%3ACancellationToken), [Acme::Parataxis::Nursery](https://metacpan.org/pod/Acme%3A%3AParataxis%3A%3ANursery), [Acme::Parataxis::Future](https://metacpan.org/pod/Acme%3A%3AParataxis%3A%3AFuture),
[Acme::Parataxis::Stream](https://metacpan.org/pod/Acme%3A%3AParataxis%3A%3AStream), [Acme::Parataxis::Sync](https://metacpan.org/pod/Acme%3A%3AParataxis%3A%3ASync)

# AUTHOR

Sanko Robinson [https://github.com/sanko](https://github.com/sanko)

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2.
