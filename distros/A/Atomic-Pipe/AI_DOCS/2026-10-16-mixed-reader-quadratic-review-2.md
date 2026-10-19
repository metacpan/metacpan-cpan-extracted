# Second review: reader fixes and size-gated compression

Review of branch `worktree-reader_quadratic` (worktree
`worktrees/reader_quadratic`) and the latest
`2026-10-16-mixed-reader-quadratic-response.md`, written 2026-10-16 from the
DBIx::QuickORM session at the owner's request. The owner has read these
findings. Anything that changes behavior or the plan still goes to the owner.

## Verdict

The code is ready; documentation and one test need work before merge.
`prove -Ilib -r t/` on the worktree: 27 files, 137 tests, pass. The reader
fixes were traced through every path (`_drained` at the loop top with public
`eof()` keeping its fill-then-check contract; `index` + 4-arg `substr`
consumption; `.=` reassembly in `_assemble`; partial parts falling to the slow
path; fast and slow paths sharing `{state}`; EOF mid-message still throwing;
bursts spanning reads; `_partial_suffix`; non-blocking readers returning empty;
`peek_line` at EOF). No correctness bugs found. All five points of the first
review were addressed, including the new small-message fast path.

## SHOULD (before merge)

### 1. Mixed-version stall with `compress_large_only`

POD lines ~2318-2322 say an older reader "will misread the flagged size
field". The actual failure, measured with master's module reading from a
branch writer: the old reader returns the preceding small message, then takes
the flagged size as ~2 GB and blocks; on a plain pipe it waits until EOF and
then throws "EOF before end of message"; on a FIFO held open by `read_fifo`
(IPC-Manager's pattern) EOF never comes, so it **hangs forever with no
error**.

The feature is off by default, so a plain upgrade is safe; the risk is any
deployment that enables it while some reader is still on an older version
(rolling upgrades, Test2-Harness2 and IPC-Manager on different versions).
At minimum, state the failure plainly in the POD and Changes ("an older reader
stalls until EOF, then throws; on a FIFO held open it hangs"). Whether to add
a protocol-level version check or handshake is the owner's call; raise it with
them rather than deciding.

### 2. Performance tables omit the one-writer large-message row

The tables around POD lines ~2400-2413 have no row for one writer sending
large messages, yet "Practical guidance" says large-only compression is "never
far behind ... in the runs above". That row is where it loses most: measured
`read_message` large-only 490 vs plain 1199 MB/s, mixed 483 vs 875 MB/s.
DBIx::QuickORM's forked fetch is exactly this topology (one writer, a reader
held back by database work) and measured size-gated compression slower in
every case (below). Add the row and qualify the guidance: compression pays off
for many writers into one reader-bound pipe, not for one writer.

### 3. Promised regression guard is missing

The handoff (item 3) and the response's own plan promised a loose
ratio/throughput assertion for multi-part reassembly and line-only mixed mode,
so the quadratic behavior cannot come back unnoticed. None exists and the
response does not say why. Add one with generous ratios (for example, time to
reassemble a 16 MB message vs a 1 MB one bounded well below 16^2, and
line-only mixed throughput within a loose factor of `read_message`), or state
explicitly why it was left out.

## OPTIONAL

- `t/bounded_buffer.t` skips when the pipe is under 52 KB, but the stream can
  reach ~56 KB; on such a platform it would deadlock rather than skip. Size
  the skip from the actual stream.
- `set_compress_large_only(0)` silently switches to compressing every message
  (documented near POD line ~2588, but easy to misuse). Consider making it
  switch to no compression, or croak, or at least warn in the POD heading.
- `compression_threshold => 0` (flag every message that shrinks, not the
  legacy format) is undocumented.
- "4-5x faster plain" holds for `read_message` (~4.3x measured) but is ~3x in
  mixed mode; say which.
- Changes entries run 50-90 words; the owner's review guidance asks for short
  single-sentence bullets (this repo's precedent already exceeds it).

## Measured gains (re-run of `bench_pipe_large.pl`, REPS=2)

The new library matches the response within 5-12%. Against master:
`read_message` large frames 183 -> ~1100 MB/s (6.7x), small events
460 -> ~570 MB/s (1.25x); `ap_zstd` unchanged. Conclusions and the POD
rewrite are otherwise supported.

## Downstream: DBIx::QuickORM forked fetch

Benchmarked against this worktree (loaded with `-I`, not installed): iterate a
forked handle to the end, best of 3, seconds.

| case | 0.032 installed | fixed | fixed + `compress_large_only` | plain own pipe |
|---|---|---|---|---|
| PostgreSQL small, 100k rows | 0.48 | 0.49 | 0.52 | 0.32 |
| PostgreSQL Test2 events | 0.58 | 0.57 | 0.67 | 0.40 |
| Percona 1,000 blobs | 1.78 | 0.53 | 0.77 | 0.28 |
| SQLite 1,000 blobs | 1.68 | 0.38 | 0.59 | 0.17 |

The fix makes blobs 3-4x faster; size-gated compression was slower in every
case. DBIx::QuickORM's forked fetch tests pass against the worktree (5 files,
111 tests). The owner's ruling for DBIx::QuickORM: keep Atomic::Pipe without
compression and require the fixed release once it is published, so please
tell the owner the version number when it ships.
