# Future::IO::Impl::IOAsync: poll handlers are not reentrant, and a cancelled poll keeps its watch

- **Dist / version:** `IO-Async` 0.805 (latest on CPAN, rechecked 2026-10-27). The module ships in the IO-Async
  dist, not in Future-IO.
- **Module:** `Future::IO::Impl::IOAsync`, `poll`, `lib/Future/IO/Impl/IOAsync.pm` line 88
- **Perl / Future / Future::IO:** perl 5, Future 0.52 (PP), Future::IO 0.23

## Summary

The `on_read_ready` handler installed by `poll` marks the front future done and only *then* removes it from the
list:

```perl
on_read_ready => sub {
   $futures->[0]->done( POLLIN );
   shift @$futures;
   ...
```

If a callback of that future turns the loop (a blocking `->get`, e.g. `Future::IO->poll(...)->get`) while the handle
becomes readable again, the handler is entered a second time — and `$futures->[0]` is still the future that is
already done:

```
IO::Async::Future=HASH(0x...) is already done and cannot be ->done at Future/IO/Impl/IOAsync.pm line 88.
```

The same handler shape exists for the write side (`on_write_ready`), not exercised here.

## Reproduction (no DBIO)

`future-io-impl-ioasync-reentrant.pl` in this gist:

```perl
use strict; use warnings;
use IO::Poll qw( POLLIN );
use Future::IO;
use Future::IO::Impl::IOAsync;

pipe( my ( $r, $w ) ) or die $!;
syswrite $w, 'x';

my $first = Future::IO->poll( $r, POLLIN );
$first->on_done( sub {
   syswrite $w, 'y';
   Future::IO->poll( $r, POLLIN )->get;
} );

my $ok = eval { $first->get; 1 };
print $ok ? "OK: reentrant poll worked\n" : "DIED: $@";
```

Run against the installed versions (2026-10-27):

```
DIED: IO::Async::Future=HASH(0x564752e4a610) is already done and cannot be ->done at Future/IO/Impl/IOAsync.pm line 88.
```

(exit 1)

## Expected / actual

- **Expected:** a callback may do a blocking wait on the same handle, as it can with the built-in implementation
  (which prints `OK: reentrant poll worked` for the same script).
- **Actual:** the nested loop turn re-enters the handler before the outer one has shifted its future off, and dies.

## A second defect: a cancelled poll keeps its watch

`poll` registers no `on_cancel`. A cancelled future stays in the list, and the loop keeps watching (and holding) the
handle until it next turns ready; only then is the cancelled future shifted off. Code that cancels polls in flight
(e.g. `wait_any` losers, or a connection torn down with a statement pending) leaves a watch and a file descriptor
behind until the next event on that handle.

## Fix

`IO-Async-0.805-future-io-poll.patch` in this gist (applies with `git apply` / `patch -p1` to the 0.805 tarball).
`poll` changes on both the read and the write side:

1. take the future off the list before completing it, and do nothing if the list is already empty:

   ```perl
   my $first = shift @$futures;
   $first->done( POLLIN ) if $first;
   ```

2. unwatch the handle only if the list is still the current one for that fileno (new helper `_release_watch`):

   ```perl
   return if scalar @$futures;
   return unless ( $by_fileno->{$fileno} // 0 ) == $futures;
   ```

3. `on_cancel` removes the future from its list and releases the watch when nothing else waits.

Change 1 alone is not enough. Two more cases show up once the first death is gone:

- **The handler fires with nobody waiting.** A callback blocks on something else, e.g.
  `Future::IO->sleep(...)->get`, while the same handle turns readable again. The handler is still registered, the
  list is empty, and `shift` returns `undef`:
  `Can't call method "done" on an undefined value`.
- **The outer handler removes the inner watch.** The nested turn completes its own future, finds the list empty,
  unwatches the handle and deletes the hash entry. If the callback then starts another poll, that poll gets a new
  list and a new watch. Back in the outer handler, the old list is empty too, and without the check it would
  unwatch the new poll. That poll then never completes.

`t/71future-io-reentrant.t` (new, in the patch, 11 tests) covers:

- nested read poll
- nested write poll (same defect, line 110)
- a poll started after the nested turn
- a nested turn with nobody waiting
- a cancelled read poll, and a cancelled write poll, releasing their handle

Results:

| Code | `t/71future-io-reentrant.t` |
|---|---|
| 0.805 | dies on the first case |
| with change 1 only | 4 cases fail |
| whole patch | all pass, stable over repeated runs |

The full IO-Async test suite passes with the patch: 65 files, 1752 tests, with and without `TEST_QUICK_TIMERS`.

## Context

Found through DBIO::Async: a synchronous statement inside a `txn_do` block, a pooled query issued synchronously
from a callback, and a blocking `listen` callback all hit the reentrancy defect. The chained form (`->then`) does not, because the
loop is not turned inside the callback. Queries cancelled or torn down in flight hit the second one.
