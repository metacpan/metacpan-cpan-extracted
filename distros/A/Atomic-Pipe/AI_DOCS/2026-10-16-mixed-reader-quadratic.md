# Mixed-data reader is quadratic; zstd speedups mostly hide it

Handoff for an agent working in this repository. Written 2026-10-16 from a
DBIx::QuickORM session (at the request of the owner, Chad Granum) that
benchmarked pipe transports. Nothing here has been changed in this repo yet;
the work below is yours to verify, fix, test, and document. Follow this
repo's own conventions and the owner's usual rules (worktree, reviews,
no merge/push without approval).

## Summary

`get_line_burst_or_data` (mixed_data_mode) reads the whole stream into
memory and then re-splits the buffer for every 4 KB part, so its cost grows
with the square of the stream size. Compression (`compression => 'zstd'`)
shrinks both the bytes and the number of parts, which hides the problem; that
is the main source of the large zstd speedups the POD reports, not
fragmentation overhead as the POD says. Without mixed mode, or with a plain
length-prefixed pipe, zstd only adds CPU.

## Mechanism (lib/Atomic/Pipe.pm, version 0.032)

- `get_line_burst_or_data` (line ~542) calls `$self->eof` on every pass of its
  `while (1)` loop.
- `eof` (line ~291) begins with `return 0 if $self->fill_buffer;`, so every
  loop pass pulls another read (64 KB) into `in_buffer` whenever data is
  available. The reader therefore drains the pipe into memory as fast as it
  can and ends up holding (nearly) the whole stream.
- Measured with `inbuf.pl` (attached): for a 14.5 MB stream of real Test2
  event JSON, `in_buffer_size` peaked at 14.5 MB.
- Each 4 KB part is then taken from the front of that buffer with a `split`
  (see `_extract_message` / `_get_from_buffer`) that copies the remainder of
  the buffer. One copy of an O(N) buffer per part, N/4096 parts: O(N^2).

## Evidence

`bench_pipe.pl` (attached) measures 1 or 8 forked writers to one reader, with
two payload shapes from a real `yath` run's events: `event` (~1.6 KB event
JSON lines, ~8800 per writer, 14.4 MB per writer) and `frame` (9 large frames
of ~1.6 MB per writer). Transports: `raw_lp` plain pipe with length-prefixed
frames; `raw_zs` the same with a zstd streaming context; `ap_*` Atomic::Pipe
`read_message`; `apm_*` Atomic::Pipe mixed mode via `get_line_burst_or_data`.
MB/s, from the attached logs:

| case | raw_lp | raw_zs | ap plain | ap zstd | apm plain | apm zstd |
|---|---|---|---|---|---|---|
| 1 writer, events | 1816 | 348 | 594 | 162 | 11.6 | 53 |
| 1 writer, frames | 1637 | 539 | 146 | 610 | 26 | 502 |
| 8 writers, events | 2425 | 729 | 555 | 288 | 0.5 | 1.8 |
| 8 writers, frames | 3334 | 1124 | 132 | 1344 | 1.3 | 240 |

- In mixed mode, plain is 50-180x slower than zstd: the quadratic cost.
- Outside mixed mode, `read_message` is linear but still pays Perl overhead
  per 4 KB part (`ap plain` 146 vs `raw_lp` 1637 on large frames), so zstd
  helps there only by reducing the part count.
- A plain length-prefixed pipe beats every Atomic::Pipe configuration.

`bench_pipe.pl` expects an `events.jsonl` next to it (one JSON event per
line). It was captured from a Test2-Harness2 `yath` run's event stream (~14 MB);
regenerate one from any recent yath run log (decompress a `events.jsonl.zst`
if needed). `inbuf.pl` uses the same file.

## What to do

1. Reproduce with the attached scripts (adjust the `use lib` path in
   `inbuf.pl`).
2. Fix the reader:
   - Do not call `fill_buffer` from `eof()` while scanning; only fill when the
     buffer cannot satisfy the next step (the in_message branch already does
     this correctly), so the buffer stays bounded by what is needed.
   - Consume from the buffer by tracking an offset (or `substr` 4-arg / chunked
     buffers) instead of `split`-ing off the front, so taking a part is O(part),
     not O(buffer).
   - Check `_extract_message`, `_get_from_buffer`, `_peek_from_buffer` and the
     non-mixed `read_message` path for the same copy-the-remainder pattern.
3. Add a regression test or bench assertion that mixed-mode throughput on a
   multi-MB stream is within a small factor of `read_message`, and that
   `in_buffer_size` stays bounded (e.g. under a few times the pipe size).
4. Re-run `bench/zstd_compression.pl` and correct the `=head2 Performance` POD
   (line ~1397): the speedup came mostly from the quadratic reader; after the
   fix, compression should be presented as a wire-size/CPU trade, with the new
   numbers.
5. Consumers to tell the owner about: Test2-Harness2 and IPC-Manager use
   Atomic::Pipe with zstd (IPC-Manager made JSON::Zstd its default in commit
   95e4f77); their numbers may change after the fix.

## Not in scope here

DBIx::QuickORM's own forked bulk insert uses a plain length-prefixed pipe and
keeps it (measured faster than every zstd option on real Test2 payloads).
Its forked fetch (`Fetch::Forked`) currently uses Atomic::Pipe with zstd and is
being benchmarked separately in that project.
