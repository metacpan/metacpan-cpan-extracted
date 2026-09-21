# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.1.0] - 2026-09-21

This started as a silly little diversion in February but I'm using this in actual projects now. I've even used it to shake out bugs in Affix.

I might move it out of the Acme namespace...

Anyway, the major win is that fiber hot path has been moved from Perl into C and roughly tripled context swapping throughput with no change to the public API.

### Added

- `Acme::Parataxis::Channel`: a buffered FIFO message queue for producer/consumer patterns between fibers. Writers block when full, readers when empty; a capacity of `1` makes it a rendezvous point. Built on two semaphores.
- `Acme::Parataxis::Future`: a one-shot placeholder for an eventual computation result. A producer fires `set_result`/`set_error` exactly once; consumers pick it up with `await`/`result` or register an `on_ready` callback.
- `Acme::Parataxis::Semaphore`: a counting semaphore with no ownership: blocked fibers are parked (no busy-wait) and resumed FIFO as permits become available.
- `Acme::Parataxis::Signal`: a two-state flag with a FIFO queue of waiters. `send` latches the signal so a later `wait` consumes it immediately, while `broadcast` wakes every queued waiter at once (and drops if nobody is waiting).

### Fixed

- Fixed crash (double-free / use-after-free) when fibers call Affix'd functions on non-threaded Perl. The bug was in Affix's `SAVEVPTR`/`SAVEDESTRUCTOR_X` arena pattern, which was not fiber-safe; now fixed upstream in Affix v1.2.5+.
- Fixed SIGSEGV on macOS and FreeBSD caused by fiber stacks being only 512KB (via `posix_memalign`). All POSIX platforms now use a 64MB `mmap`-backed stack with a PROT_NONE guard page, matching the Linux path. The SIGSEGV guard handler is also available on macOS/FreeBSD now.
- Fixed FreeBSD compilation: added `MAP_ANONYMOUS` w/ `MAP_ANON` fallback.
- Fixed macOS SIGBUS: the guard region size is now derived from `sysconf(_SC_PAGESIZE)` at runtime so it always covers at least one full page (16 KiB on Apple Silicon). Also fixed `cleanup()` to use `munmap()` instead of `free()` on non-Linux POSIX platforms.
- `is_finished()` now rejects fiber ids of `MAX_FIBERS` or greater instead of reading out of bounds of the fiber table.
- Closed a busy-spin footgun: `wait`, fiber `await`, `Semaphore` waits, and `Signal->wait` now croak instead of burning 100% CPU when called from outside the scheduler, and `->new` croaks when the 1024-slot fiber table is exhausted rather than creating a fiber that can never run.
- A fiber that yields during its initial run is now re-enqueued by the scheduler instead of being dropped, which previously could hang a regex-heavy workload.
- The scheduler no longer hangs when a fiber object is created but never spawned (`->new` without `spawn`): live-fiber tracking only counts fibers that have actually started, matching Coro's ready-queue semantics.
- `async`/`run` is now re-entrant: a nested `async` inside another `async` or inside a fiber shares the one run loop (like Coro's single global scheduler) and returns the block's value, instead of clobbering the outer scheduler and deadlocking.
- A destroyed fiber's id is kept out of the free list until every job it submitted has been reclaimed, so a stale completion can never be misdelivered to a (or corrupt) fiber that later reuses the id.
- Pending-job tracking now reads the C-side outstanding job count instead of a run-local counter, so jobs left over from a `stop`ped run are drained and handled by the next run instead of tripping `FATAL: deadlock detected` or sitting in the done-queue forever.
- `Semaphore` `up`/`adjust` skip stale (already destroyed) waiters instead of consuming a wake that should go to a live fiber.
- Channel constructors now reject a capacity below 1 instead of deadlocking on it at load time.
- The 1024-slot job queue is no longer fatal on the first try: `_submit_job` yields once and retries before croaking.
- `Future::set_result`/`set_error` wake awaiters exactly once instead of appending a duplicate `_wake_waiters` callback on every `await`.

### Changed

- Spawned fibers run inline at spawn time.
- The fiber registry is replaced by strong references to each fiber object in C.
- Fiber completion moved from a Perl method into C: the entry point writes state directly into the object's slots with `av_store`, and only dispatches callbacks when callbacks were actually registered.
- To save time on FFI boundary crossings, `spawn` now performs the whole create run sequence in a single call and builds the fiber object in C.
- Fiber objects are incrementally-filled AV*s instead of HV*s.
- On x86_64 ELF, context switching uses a hand written trampoline that only saves the callee-saved registers and stack pointer, avoiding `swapcontext`'s signal-mask syscall.
- `spawn` and `await` hot paths flattened by inlining helpers.
- Worker threads block on `select()` for the full `await_read`/`await_write` timeout instead of polling every 10ms, cutting idle syscalls by ~50x. On POSIX a shutdown pipe wakes any worker blocked in `select()` during `cleanup()`.

## [v0.0.10] - 2026-02-22

This version comes with a dynamic thread pool and an improved API.

### Added
- New ergonomic API using exported functions like `async { ... }`, `fiber { ... }`, and `await( $target )`.

### Changed
- Refactored native thread pool to use cond vars (`PARA_COND_*`) instead of busy polling, reducing idle CPU usage to near zero.
- Switched to a global job queue for the thread pool for better load balancing across worker threads.
- Reduced default fiber stack size from 4MB to 512K.
- Worker threads are now only spawned when the first asynchronous job is submitted.
- Increased `MAX_FIBERS` limit to 1024.
- Expose thread pool config with `set_max_threads` and `max_threads`.

## [v0.0.9] - 2026-02-21

Asynchronous HTTP::Tiny is basically a semi-automatic footgun.

### Fixed
- Resolved `AvFILLp(av) == -1` and `!AvREAL(av)` assertion failures in `Perl_pp_entersub` on `DEBUGGING` builds of Perl. This was fixed by ensuring Slot 0 (the argument array) of the next pad depth is correctly initialized during fiber context switches.

### Changed
- Increased fiber stack size to 4MB to provide better support for deep Perl calls and regex operations. This is a temp solution.

## [v0.0.8] - 2026-02-19

All the remaining failing smokers all had old versions of Affix and sure enough when I installed v1.0.6, I saw the same failure. Always the most obvious thing...

### Changed
- Require Affix v1.0.7

## [v0.0.7] - 2026-02-18

Another dist targetting a specific CPAN smoker. I cannot replicate the failure in https://www.cpantesters.org/cpan/report/f0ca1d14-0cfa-11f1-9988-e7d94c615303, so I'm just trying different things...

### Fixed?
- Arguments passed to a fiber might not be released until the fiber object was destroyed.

## [v0.0.6] - 2026-02-18

### Fixed
- Resolved assertion failures in `Perl_cx_popsub_args` and `Perl_pp_entersub` when running on a `DEBUGGING` build of Perl. This was fixed by ensuring `CvDEPTH` and pads are correctly restored during context switches. (I hope...)

### Added
- Added `--debug` build to GitHub Actions matrix to ensure future compatibility with Perl debugging builds.

### Changed
- Refactored `swap_perl_state` to be more robust regarding Perl's internal stack management.

## [v0.0.5] - 2026-02-18

### Changed
- I'm honeslty just throwing stuff at the wall. Between my local machines and GH CI workflows, I cannot replicate some of the failures I'm seeing from smokers which makes them virtually impossible to resolve.

## [v0.0.4] - 2026-02-17

### Changed

  - Attempt to only spawn max X threads in `t/006_parallel.t` where X is 3 or the `get_thread_pool_size()`? See https://www.cpantesters.org/cpan/report/ecf1410e-0c46-11f1-8628-aee76d8775ea
  - Recalculate `PL_curpad = AvARRAY(PL_comppad)` in `swap_perl_state`? See https://www.cpantesters.org/cpan/report/e7244bd8-0c44-11f1-b3ab-94362698fc84

## [v0.0.3] - 2026-02-17

### Changed
  - Adding an optional timeout to `await_read` and `await_write`.
  - Allow fibers to return complex data (AV*, HV*).

## [v0.0.2] - 2026-02-17

### Fixed
  - Fixed segfault in `coro_yield` by adding NULL checks for destroyed or missing fibers.
  - Resolved stall in exception handling by introducing `last_sender` tracking to prevent `parent_id` cycles.

### Changed
  - Made unit tests a lot more noisy

## [v0.0.1] - 2026-02-16

### Changes
  - It exists! It shouldn't but it does.

[Unreleased]: https://github.com/sanko/Acme-Parataxis.pm/compare/v0.1.0...HEAD
[v0.1.0]: https://github.com/sanko/Acme-Parataxis.pm/compare/v0.0.10...v0.1.0
[v0.0.10]: https://github.com/sanko/Acme-Parataxis.pm/compare/v0.0.9...v0.0.10
[v0.0.9]: https://github.com/sanko/Acme-Parataxis.pm/compare/v0.0.8...v0.0.9
[v0.0.8]: https://github.com/sanko/Acme-Parataxis.pm/compare/v0.0.7...v0.0.8
[v0.0.7]: https://github.com/sanko/Acme-Parataxis.pm/compare/v0.0.6...v0.0.7
[v0.0.6]: https://github.com/sanko/Acme-Parataxis.pm/compare/v0.0.5...v0.0.6
[v0.0.5]: https://github.com/sanko/Acme-Parataxis.pm/compare/v0.0.4...v0.0.5
[v0.0.4]: https://github.com/sanko/Acme-Parataxis.pm/compare/v0.0.3...v0.0.4
[v0.0.3]: https://github.com/sanko/Acme-Parataxis.pm/compare/v0.0.2...v0.0.3
[v0.0.2]: https://github.com/sanko/Acme-Parataxis.pm/compare/v0.0.1...v0.0.2
[v0.0.1]: https://github.com/sanko/Acme-Parataxis.pm/releases/tag/v0.0.1
