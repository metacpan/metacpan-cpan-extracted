# Response: mixed-data reader is quadratic

Reply to `2026-10-16-mixed-reader-quadratic.md`, written 2026-10-16 by the
agent working in this repository (Atomic-Pipe 0.033-dev, Perl 5.44.0, Linux).
I have only investigated so far: nothing in `lib/` has changed. The
experiments ran on a scratch copy with each fix behind an env-var toggle; that
copy is attached as `prototype.diff` (test scaffolding, not a patch to apply).

## Short version

- **Confirmed:** the reader drains the pipe into memory, and the prefix and
  postfix `split`s make mixed mode quadratic. The POD's zstd speedup is mostly
  this bug.
- **Wrong:** `_get_from_buffer` / `_peek_from_buffer` are not part of the
  problem. 4-arg `substr($buf, 0, $n, '')` costs O(1) in Perl.
- **Missed:** the multi-part reassembly in `_extract_message` is quadratic in
  message size. It hits `read_message` (non-mixed) too. It explains the
  `ap plain` frame numbers, not "per-part Perl overhead".
- **Missed:** line-only traffic in mixed mode (child STDOUT/STDERR in
  Test2-Harness) is the worst case: 0.6 MB/s before the fixes.

## Reproduction

`events.jsonl` was not available here, so `gen.pl` (attached) builds a
synthetic stand-in: 12100 Test2-style event JSON lines, 14.4 MB, about 1.2 KB
each. Your `bench_pipe.pl` and `inbuf.pl` were run unmodified except for
`use lib $ENV{APLIB}`.

`inbuf.pl`, baseline:

    zstd=0 msgs=12100 time=1.79s successful_reads=371  max_in_buffer=14.5MB
    zstd=1 msgs=12100 time=0.55s successful_reads=6319 max_in_buffer=4.7MB

The same with the eof, split and concat fixes:

    zstd=0 msgs=12100 time=0.07s successful_reads=225  max_in_buffer=0.1MB
    zstd=1 msgs=12100 time=0.12s successful_reads=8209 max_in_buffer=0.0MB

With the fixes, plain mixed mode is now faster than zstd mixed mode, as you
predicted.

## Point by point

### 1. `eof()` filling from inside the loop: confirmed

The loop-top check at `lib/Atomic/Pipe.pm:564` calls `$self->eof`, and
`eof()` calls `fill_buffer`. In the prototype that check reads state directly:
EOF flag set, `IN_BUFFER_SIZE` zero, and the `lines` and `burst` buffers
empty. No other change was needed, because every branch that needs more bytes
already fills on demand (the in_message branch, `_from_buffer`, and the
`unless ($self->{+IN_BUFFER_SIZE} || $self->fill_buffer())` at the bottom).
Public `eof()` is unchanged. Callers rely on it filling: `t/` passes, and
callers like `last if !%m && $r->eof` need it.

### 2. Prefix and postfix `split`: confirmed

`split /(\Q$prefix\E)/, $self->{+IN_BUFFER}, 2` (`:664`) and the postfix twin
(`:628`) return a copy of the rest of the buffer. Replacing them with
`index` plus 4-arg `substr` makes each step O(consumed).

### 3. `_get_from_buffer` / `_peek_from_buffer`: not a problem

`substr($self->{+IN_BUFFER}, 0, $size, '')` uses Perl's front-chop
optimization, which moves the string's start pointer instead of copying.
Measured with `prim.pl` (attached), consuming a buffer in 4 KB chunks:

| primitive | 4 MB | 16 MB |
|---|---|---|
| 4-arg `substr` off front | 0.000s | 0.001s |
| `split` off front | 0.028s | 0.475s |
| `$b = $b ? $b . $d : $d` (reassembly) | 0.060s | 0.981s |
| `$b .= $d` | 0.000s | 0.001s |

Don't rewrite `_from_buffer`; it is already the pattern to copy.

### 4. NEW: quadratic reassembly in `_extract_message`

```perl
$state->{buffers}->{$tag} = $state->{buffers}->{$tag} ? $state->{buffers}->{$tag} . $data : $data;
```

This builds a new string for each part. A 1.6 MB message has about 400 parts,
so it copies roughly 320 MB. `.=` fixes it. Measured on `read_message` (no
mixed mode), 1 writer, 1.6 MB frames, with `MALLOC_MMAP_THRESHOLD_` pinned:

| | ap_plain frames |
|---|---|
| baseline | ~185 MB/s |
| `.=` fix only | ~1000–1150 MB/s |

That's about 6x, on the path that DBIx::QuickORM's `Fetch::Forked` and
anything else using `read_message` with large messages takes. The
"per-part overhead" explanation in your Evidence section should be dropped.
Mixed mode gains too, once the eof and split fixes are also in: frames go
from about 160 to about 660–700 MB/s (see the matrix below). An earlier note
said mixed mode didn't gain; that came from the run with the zsh `env` bug
described under Measurement traps.

### 5. NEW: line-only mixed traffic

`lines.pl` (attached) sends 150k lines of 100 bytes (15 MB) as raw lines, with
no bursts, read with `get_line_burst_or_data`:

| | time | MB/s |
|---|---|---|
| baseline | 24.28s | 0.6 |
| eof + split + concat fixes | 0.77s | 19.6 |

That's 30x. This is how Test2-Harness reads child output, so it probably
matters more in practice than the zstd story. What's left is per-call Perl
overhead (about 5 µs per line). I tried rewriting the line `split` at `:569`
with match plus 4-arg `substr`: it gave no measurable gain, and the first
attempt broke `t/peek_line.t` and `t/mixed_data_mode.t`. The original `split`
clears `lines` on the EOF path that returns a line without a newline, and the
rewrite didn't, so the line came back twice. Not recommended unless a profile
shows it matters.

## Full matrix

All 22 test files pass with the eof, split and concat fixes on. MB/s,
`READER=fast`, best of 3 runs, `MALLOC_MMAP_THRESHOLD_=131072`. "—" means the
run hit the 900 s timeout or the timeout cut it off before that row (the
baseline 8-writer mixed rows take minutes per run, as in your `pipe_w8b.log`).

| case | baseline | eof | split | eof+split | eof+split+concat |
|---|---|---|---|---|---|
| apm_plain events w=1 | 3.2 | 200 | 176 | 248 | 230 |
| apm_zstd  events w=1 | 4.4 | 96 | 81 | 103 | 91 |
| apm_plain events w=8 | — | 200 | 187 | 238 | 231 |
| apm_zstd  events w=8 | — | 95 | 93 | 100 | 100 |
| apm_plain frames w=1 | — | 155 | 152 | 163 | **659** |
| apm_zstd  frames w=1 | — | 492 | 474 | 551 | 476 |
| apm_plain frames w=8 | — | 146 | 146 | 158 | **696** |
| apm_zstd  frames w=8 | — | 839 | 832 | 913 | **1004** |
| ap_plain  frames w=1 | — | 188 | 186 | 191 | **1113** |
| ap_zstd   frames w=1 | — | 502 | 458 | 512 | 502 |
| ap_plain  frames w=8 | — | 176 | 177 | 178 | **1091** |
| ap_zstd   frames w=8 | — | 1000 | 985 | 1000 | 1143 |

How to read it:

- Either the eof fix or the split fix alone removes the quadratic cost. With
  the eof fix the buffer stays small, so the copies are cheap; with the split
  fix nothing gets copied. Land both, so neither has to hold up the other.
- The concat fix is what makes large plain messages fast: about 4x in mixed
  mode and about 6x in `read_message`.
- After all three fixes, plain beats zstd for small messages by 2–2.5x, and
  for large messages with one writer.
- zstd still wins for large messages with 8 writers in mixed mode (1004 vs
  696). Compression runs in parallel in the writers and the single reader only
  decompresses, so zstd shifts work off a reader that's the bottleneck. That
  is the honest pitch for the POD, and a reason to consider a size threshold
  for compression (see below).

## Follow-up idea: size-gated compression

The owner asked about compressing only messages above some size. The data
supports it: small messages lose with zstd, and large messages from many
writers win. Sketch:

- New option, e.g. `compression_min_size`, configurable. Make the default a
  few × PIPE_BUF (the crossover depends on writer count). Setting it to 0
  keeps today's behavior.
- Per-message flag: the high bit of the 32-bit `size` field in the part header
  (`size` never goes above PIPE_BUF, so the bit is free). Both ends must
  enable it, the same as `compression` today.
- Don't sniff the zstd magic number (`28 B5 2F FD`) instead of using a flag:
  arbitrary binary payloads can start with it.
- Bursts have no header. Leave them out of a first version, or give them a
  leading flag byte.
- `keep_compressed` then returns no `compressed` value for messages that were
  sent plain. Document that.
- Measure the threshold after the reader fixes land, not before.

## Measurement traps

Things that tripped me up when re-running this:

- **zsh word splitting:** `env $cfg perl ...` with `cfg="A=1 B=1"` sets only
  `A`, to the value `"1 B=1"`, because zsh doesn't split unquoted parameters.
  My first combination table was invalid for this reason. Use `env ${=cfg}`.
- **malloc noise:** large-string `.=` results swing by up to 3x between runs
  because of glibc's dynamic mmap threshold. Pin it with
  `MALLOC_MMAP_THRESHOLD_=131072` when comparing.
- The host also had load from other work (load average up to 33 on 32 cores),
  so treat single numbers as approximate.

## Plan in this repo (pending owner approval)

1. Worktree; land fixes 1, 2 and 4 as above. Keep `eof()`'s public behavior.
2. Regression tests: mixed mode on a multi-MB stream keeps `in_buffer_size`
   bounded (under a few × read size); multi-part reassembly and line-only
   throughput stay within a factor of `read_message`. Use ratio assertions so
   they don't flake on CPAN Testers.
3. Re-run `bench/zstd_compression.pl` and rewrite `=head2 Performance`:
   compression becomes a wire-size/CPU trade, and the "~1000x from avoided
   fragmentation" and "pipe buffer size has minimal impact" claims go away.
4. Tell the owner about the downstream effects on Test2-Harness2 and
   IPC-Manager (whose zstd default may no longer be the faster choice).

## Attachments (`2026-10-16-mixed-reader-quadratic-response/`)

- `prototype.diff`: env-gated scratch changes (`AP_FIX_EOF`, `AP_FIX_SPLIT`,
  `AP_FIX_CAT`, `AP_FIX_LINES`; the last one is the broken line-split rewrite)
- `gen.pl`: synthetic `events.jsonl` generator
- `prim.pl`: cost of each buffer primitive
- `lines.pl`: line-only mixed-mode throughput

---

# Update: implemented, reviewed, and answers to the review

Added later on 2026-10-16. This answers
`2026-10-16-mixed-reader-quadratic-review.md`. The work is on branch
`worktree-reader_quadratic` in `worktrees/reader_quadratic` (7 commits on top
of master `b80e2d4`). It is **not merged or pushed**; that waits for the owner.

## What landed

| commit | what |
|---|---|
| `3c7a19e` | Reader fixes 1, 2 and 4 from above, burst-boundary fixes (below), `compress_large_only` / `compression_threshold`, tests, rewritten Performance POD |
| `38b734d` | `compress_large_only => 1` turns on zstd by itself; no separate `compression` option needed |
| `91eb020` | Synopsis example for large-only; the docs give the default threshold as a number; `compression_threshold()` returns the threshold in use |
| `a49cadd` | Fix pre-existing unresolved POD links (podchecker is now clean) |
| `3196135` | Ignore `worktrees/` |
| `08bfc7e` | Pre-existing bug: a blocking `read_message` with a `read_size` smaller than one part returned undef (looks like EOF) partway through the stream; `_from_buffer` now keeps reading while reads return data |
| `3f46f3e` | Fast path: a message part already fully buffered is taken in one step (review gaps 1 and 2, below) |

Owner decisions that shaped this:
- **Default threshold:** a message is compressed when it would otherwise need
  splitting: longer than `PIPE_BUF` minus framing, which is 4080 bytes on
  Linux and 4077 in mixed mode. It is compressed first and split only if still
  too big.
- **Flag:** the high bit of the part-size header field.
- **Bursts:** never compressed in large-only mode.

## Bugs the independent review found in my first version

A separate review agent checked the change twice before commit. All of these
are fixed and have tests (`t/burst_boundaries.t`, read sizes 1..65536, default
and 3-byte delimiters):

1. **Critical, introduced by the eof fix: bursts that span two reads were
   corrupted.** When the postfix wasn't in the buffer yet, the code fell
   through to the line scan and returned the rest of the burst as line data.
   HEAD had the same fall-through, but rarely hit it because it read the whole
   pipe into memory first. With a bounded buffer, 366 of 600 items came out
   wrong at the default read size. The burst path now keeps reading until the
   postfix arrives.
2. **The message key `\x10` was honored anywhere in a burst, not just at its
   start.** A burst continuation whose first byte was `\x10` was taken for a
   message.
3. **Multi-byte `burst_prefix` / `burst_postfix`:**
   - a delimiter split across two reads wasn't found;
   - the message terminator was checked against only one byte of the postfix,
     so multi-byte postfixes never worked with messages.
4. **A partial delimiter at the end of the buffer is now held back only when
   it really is one.** My first version held back the last few bytes of
   every line, which deadlocked request/reply use with custom delimiters.
5. **A non-blocking reader waiting on the rest of a burst kept the CPU busy
   inside one call** (about 1.35 s); it now returns empty instead.

Still open: a multi-byte custom `message_key` doesn't work. That limitation
predates this work.

## Final numbers (branch head `3f46f3e`, synthetic corpus, MB/s, best of 5)

| case | raw_lp | ap plain | ap zstd | ap large-only | apm plain | apm zstd | apm large-only |
|---|---|---|---|---|---|---|---|
| events w=1 | 2042 | 555 | 129 | 477 | 359 | 121 | 335 |
| events w=8 | 2278 | 649 | 140 | 587 | 344 | 119 | 334 |
| frames w=1 | 3137 | 1337 | 530 | 520 | 883 | 482 | 503 |
| frames w=8 | 2990 | 1339 | 1148 | 1171 | 878 | 1143 | 1112 |

The shipped `bench/zstd_compression.pl` (1 writer, mixed mode, 100 MB) gives
plain 0.29 → about 530 MB/s, L3 about 208, and large-only about 245.

Before and after the fast path alone (plain, same bench, best of 5):

| case | before | after | gain |
|---|---|---|---|
| events, `read_message`, w=1 / w=8 | 437 / 421 | 555 / 649 | 1.3x / 1.5x |
| events, mixed, w=1 / w=8 | 223 / 220 | 359 / 344 | 1.6x |
| frames, `read_message`, w=8 | 1137 | 1339 | 1.2x |
| frames, mixed, w=1 / w=8 | 671 / 667 | 883 / 878 | 1.3x |

What the numbers now say about compression:
- **Small messages:** plain is about 4.3–4.6x faster than zstd with
  `read_message` and about 3x faster in mixed mode.
- **`read_message`:** plain wins even for large messages from 8 writers (1339
  vs 1148).
- **Mixed mode:** zstd still wins only for large messages from many writers
  (1143 vs 878). Each part costs the reader more there, and compression runs in
  parallel in the writers.
- **Large-only:** stays within about 15% of the faster of plain and zstd
  everywhere except one-writer large messages, where it pays compression CPU
  for nothing (520 vs 1337).

The POD's Performance section says this and carries these numbers.

## Review gaps, point by point

1. **Small-message `read_message` rows:** measured; they are in the tables
   above. NYTProf showed per-message overhead spread over many small steps:
   two sub layers per buffer read (`_get_from_buffer` → `_from_buffer` with a
   param hash), and a fresh `%key` hash, parts array, buffers hash and `join`
   tag per message, even for single-part messages. **Done in `3f46f3e`:**
   - `_take_part` takes a whole buffered part (header and payload, plus key
     and postfix in mixed mode) in one step.
   - `_assemble` skips the bookkeeping for a complete single-part message.
   - Anything split across reads still takes the old step-by-step path. Both
     paths share the reassembly state, so one message can mix them.

   Result: 1.3–1.5x. That's below my 1.5–2.5x estimate. What's left is Perl
   call overhead (each message still passes through about four subs).
   Inlining one more of them and unpacking the header in place measured
   within noise, so I reverted the inlining. `raw_lp` at about 2000 MB/s
   stays out of reach for a Perl framing layer.
2. **Mixed-mode large plain messages:** profiled. Nothing quadratic is left;
   the gap was per-part cost (5 buffer calls plus loop passes per part,
   against 2 in `read_message`). **Done in `3f46f3e`:** the same fast path,
   hooked into the burst branch where line ordering is already settled. Mixed
   frames went from 667 to 878 MB/s with 8 writers. zstd still wins there
   (1143), as noted above. That is now mostly the writers-do-the-CPU-work
   effect, plus fewer passes through the mixed-mode loop.

   The fast path had its own review pass, which approved it. The reviewer
   added randomized interleaving tests: two writers, random chunking, random
   read sizes, single messages split across both paths (e.g. 21 parts fast,
   102 slow in one run). It also checked a bad-terminator case, which gives
   the same error as before. New test: `t/fast_path.t`.

   While testing, `t/fast_path.t` found the pre-existing small-`read_size` bug
   fixed in `08bfc7e` (test: `t/small_read_size.t`, which fails on HEAD).
3. **Skip compression when it doesn't shrink:** done. A message is sent plain,
   with the flag clear, unless the compressed form is strictly smaller.
4. **Threshold default:** the owner chose the split size. The POD presents
   compression as a wire-size/CPU trade and names the topology it helps
   (large messages, many writers, one reader). It no longer says compression
   is generally faster.
5. **Smaller points:**
   - `keep_compressed`: the behavior changes only in the new opt-in mode; the
     legacy `compression` behavior and wire format are unchanged. Documented
     in Changes and the POD.
   - Downstream check:
     - IPC-Manager doesn't use Atomic::Pipe compression or `keep_compressed`.
       Its zstd is in its own `JSON::Zstd` serializer, so the payload is
       compressed before Atomic::Pipe sees it.
     - IPC-Manager does reach into `$p->{state}{parts}` and `{buffers}` in
       `peer_left`. That structure is unchanged.
     - Test2-Harness2 has no direct Atomic::Pipe use.
   - Bursts being excluded from large-only mode is stated in the POD.
   - The typo is fixed.

## Not measured

- **The real Test2 `events.jsonl`:** not available here. Every number uses the
  synthetic corpus from `gen.pl` (about 1.2 KB events, 14.4 MB).
- **`READER=json`:** not re-run after the fix (only `fast`).
- **DBIx::QuickORM `Fetch::Forked`:** to be re-benchmarked on your side once
  the fixed Atomic::Pipe is released.
- **IPC-Manager:** now that Atomic::Pipe is linear and faster, IPC-Manager may
  want to re-measure whether its zstd serializer default still pays off. Small
  messages are 3–4.6x faster plain in these runs, depending on mode.

## Branch state

`worktree-reader_quadratic` has 8 commits on master `b80e2d4` (the 8th,
`536609a`, is covered in the response to the second review below). The full
suite passes (28 files) and podchecker is clean. It is not merged or
pushed; that waits for the owner.

New attachments:
- `bench_pipe_large.pl`: your `bench_pipe.pl` with `use lib $ENV{APLIB}` and
  `ap_large` / `apm_large` transports
- `prof.pl`: single reader for NYTProf (`perl -d:NYTProf prof.pl event|frame 0|1`)

---

# Response to the second review

Answers `2026-10-16-mixed-reader-quadratic-review-2.md`. Everything is in
commit `536609a` on the same branch (8 commits on master now). The suite
passes: 28 files. podchecker is clean.

## SHOULD items

1. **Mixed-version stall:** the owner ruled that readers and writers on
   different versions are unsupported: document it, and add no handshake
   ("Atomic::Pipe is almost always used by forked processes to communicate").
   The POD bullet is now headed **Mixing versions is not supported** and
   states the failure plainly. On a plain pipe the older reader stalls until
   EOF and throws `EOF before end of message`; on a FIFO that stays open it
   hangs forever with no error. Changes says the same in one line.
2. **One-writer rows:**
   - Added. Each POD table has 1-writer and 8-writer rows for both mixed mode
     and `read_message`.
   - With one writer, compression of any kind runs at about half the speed of
     plain for large messages (`read_message` 1337 plain vs 520 large-only;
     mixed 883 vs 503).
   - The guidance now says compression only pays off for many writers into
     one reader in mixed mode. It names a reader held back by other work
     (your database case) as one that gains nothing.
   - "Never far behind" became "with many writers, within about 15%".
3. **Regression guard:** added `t/linear_scaling.t`.
   - For multi-part reassembly, mixed-mode messages and mixed-mode lines, it
     times 2 MB against 16 MB (best of 3) and requires that 8x the data takes
     under 32x the time. Fixed code measures 6–8x; master measures 53–60x
     (mixed lines take 23 s at 16 MB), so it fails on master.
   - It passed three runs in a row under `prove -j16`.
   - It is skipped when `AUTOMATED_TESTING` is set unless `EXTENDED_TESTING`
     is too, so a loaded CPAN smoker can't flake on it. It runs for
     developers and in normal installs.

## OPTIONAL items

- **`t/bounded_buffer.t` skip:** fixed. The test now builds the stream first,
  counts its exact size on the wire, and skips if the pipe is smaller. I
  checked the count against the real wire bytes: 54610 and 54429, exact in
  both modes.
- **`set_compress_large_only(0)`:** the owner chose "undo what it enabled".
  If compression was on only because of `compress_large_only` (constructor or
  setter), turning it off turns compression off too. A compression setting
  the caller made explicitly stays on, and the pipe goes back to compressing
  everything; a later explicit `set_compression` call counts as explicit.
  Tested and documented.
- **`compression_threshold => 0`:** documented. It compresses every message
  that compression shrinks, still in the flagged format, so incompressible
  messages go out as-is.
- **"4–5x":** corrected above, by mode (about 4.3–4.6x with `read_message`,
  about 3x in mixed mode).
- **Changes:** rewritten as 16 one-sentence entries.

## For the owner: version to require downstream

The branch's `$VERSION` is **0.033**. Once it's released, DBIx::QuickORM can
require `Atomic::Pipe 0.033`. Your forked-fetch numbers (blobs 3–4x faster;
size-gated compression slower in every case) match the one-writer rows now
in the POD.
