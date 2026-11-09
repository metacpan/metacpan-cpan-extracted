# Future::IO built-in implementation: cancelling a poll from the callback of a poll in front of it kills the round

- **Dist / version:** `Future-IO` 0.23 (latest on CPAN, rechecked 2026-10-27)
- **Module:** `Future::IO` (the built-in `Future::IO::_DefaultImpl`), `_await_once`, `lib/Future/IO.pm` line 890
- **Perl / Future:** perl 5, Future 0.52 (PP)

## Summary

The built-in implementation's `_await_once` iterates the poller list with the length cached before the loop
(`my $npollers = @pollers`). A callback of a resolved poll that cancels a poll *behind* it in the list makes the
`on_cancel` handler splice that poll out of `@pollers`, so the cached length is too large; the loop then reaches an
index past the end, `$pollers[$idx]` is `undef`, and `$p->fh` dies:

```
Can't call method "fh" on an undefined value at Future/IO.pm line 890.
```

The commonest way to get there is `Future->wait_any($a, $b)` over two polls: when `$a` is done, `wait_any` cancels
`$b` from inside `$a`'s callback.

## Reproduction (no DBIO)

`future-io-builtin-cancel-in-callback.pl` in this gist:

```perl
use strict; use warnings;
use IO::Poll qw( POLLIN );
use Future;
use Future::IO;

pipe( my ( $r1, $w1 ) ) or die $!;
pipe( my ( $r2, $w2 ) ) or die $!;
syswrite $w1, 'x';
syswrite $w2, 'x';

my $first  = Future::IO->poll( $r1, POLLIN );
my $second = Future::IO->poll( $r2, POLLIN );
$first->on_done( sub { $second->cancel } );

my $f = Future->wait_any( $first, Future::IO->sleep(5) );
my $ok = eval { $f->get; 1 };
print $ok ? "OK: round survived\n" : "DIED: $@";
```

Run against the installed Future::IO 0.23 (2026-10-27):

```
DIED: Can't call method "fh" on an undefined value at Future/IO.pm line 890.
```

(exit 1)

## Expected / actual

- **Expected:** the round finishes; `$first` is done, `$second` is cancelled, `->get` returns.
- **Actual:** the round dies in `_await_once`, inside the `->get` of whoever drives the loop. The `wait_any`
  future is already done at that point, so the caller sees an exception from a call that has nothing wrong with it.

## Fix

`Future-IO-0.23-poll-round.patch` in this gist (applies with `git apply` / `patch -p1` to the 0.23 tarball).

`_await_once` no longer walks `@pollers` by index. It takes the pollers present at the start of the round as a
snapshot, skips any whose future is already ready (cancelled or completed by an earlier callback of the same round),
and removes a completed poller from `@pollers` by identity. Pollers pushed during the round still wait for the next
one, as before; the `blocking` save/restore around each poller is unchanged.

The index walk breaks in two more ways than the one above, and the patch covers all three:

1. a callback cancels a poller **behind** it: the cached length runs past the end (`Can't call method "fh"`);
2. a callback cancels a poller **in front of** it: the indices shift, a ready poller is skipped or the loop again
   runs off the end;
3. a callback turns the loop (`->get` on a later poller): the nested round splices that poller out from under the
   outer one.

`t/03poll-cancel-in-callback.t` (new, in the patch) has one case for each. Against 0.23 it fails 4 of 8 tests; with
the patch all pass. The full Future-IO test suite passes with the patch (20 files, 117 tests), and so does the
IO-Async suite run against the patched Future::IO.

## Context

Found through DBIO::Async (`Future->wait_any` over two pooled database queries, and `disconnect` from a poll
callback). Not DBIO specific: any cancel from a poll callback of a later poll reaches it.
