# Review of the response: mixed-data reader is quadratic

Review of `2026-10-16-mixed-reader-quadratic-response.md` (the 11:33 version
with the full matrix and the size-gated compression sketch), written
2026-10-16 from the DBIx::QuickORM session at the owner's request. The owner
has seen these points; treat them as input, not new rulings. Anything that
changes the plan or a public behavior still goes to the owner.

## Agreed

- Fixes 1 (eof fill inside the loop), 2 (prefix/postfix `split`) and 4
  (`.=` reassembly) are well supported by the matrix and the passing suite.
  Landing both 1 and 2 even though either alone removes the quadratic cost is
  right.
- Leaving `_get_from_buffer` / `_peek_from_buffer` alone is right; the
  correction to the handoff on 4-arg `substr` stands.
- A per-message flag in the high bit of the part header's `size` field is
  sound, and not sniffing the zstd magic is correct.
- Measuring the compression threshold after the reader fixes land is the
  right order.

## Gaps to close

### 1. Add non-mixed small-message rows to the matrix

The matrix has `ap_*` (plain `read_message`) only for large frames. The
small-message `read_message` path is what DBIx::QuickORM's `Fetch::Forked`
uses (one frozen row per message). Before the fixes it ran at 594 MB/s
against 1816 MB/s for a plain length-prefixed pipe (`pipe_w1.log`, `event`
shape). That gap is per-message cost, not quadratic, so fixes 1, 2 and 4 may
not move it. Please add `ap_plain` / `ap_zstd` for the `event` shape, 1 and 8
writers, so we know whether that path still has headroom; if it does, a
profile of `read_message` on small messages would be the next step.

### 2. Profile mixed mode on large plain messages before choosing a threshold

After all three fixes, large frames with 8 writers:

- mixed mode: plain 696, zstd 1004 MB/s;
- `read_message`: plain 1091, zstd 1143 MB/s.

The non-mixed path is nearly even, so the remaining zstd win in mixed mode
looks like leftover mixed-mode cost on large plain messages (you noted
earlier that mixed-mode frames are "bound by something else and needs a
profile"). If profiling finds and removes it, the case for size-gated
compression narrows to genuinely bandwidth- or reader-bound workloads. Please
profile and, if it is a fixable inefficiency, fix it before the threshold
work, and re-run the matrix.

### 3. Skip compression when it does not shrink the message

With a per-message flag, the writer can compress, compare sizes, and send the
original with the flag clear when the compressed form is not smaller (or not
smaller by some margin). Test2-Harness2 sends and stores event blobs that are
often already zstd-compressed (`events.jsonl.zst`); recompressing them is pure
CPU. This costs nothing in the protocol and should be part of the first
version of size-gated compression.

### 4. Threshold default

The crossover depends on topology. One writer with a reader slowed by other
work (the ORM's pattern: the parent is bottlenecked on the database) never
benefits from compression; many writers into one fast reader can. Pick the
default from measurements after gaps 1 and 2, and document the trade-off in
the POD rather than implying compression is generally faster.

### 5. Smaller points

- `keep_compressed` returning no `compressed` value for messages sent plain
  changes behavior for existing callers that set it; document it in Changes
  and the POD, and check Test2-Harness2 / IPC-Manager for callers that rely on
  `compressed` always being present.
- Leaving bursts out of the first version of size-gated compression is fine;
  say so in the POD.
- Typo in the response's "Measurement traps" heading line: "Things that
  tripped me up when re-running this: for anyone re-running this:".

## Downstream

DBIx::QuickORM: `Fetch::Forked` now uses Atomic::Pipe without compression on
a 1MB pipe and will be re-benchmarked once the fixed Atomic::Pipe is released
and installed (baseline: PostgreSQL small rows 0.48 s via Atomic::Pipe vs
0.32 s via a plain pipe, 100k rows; Percona 1,000 blobs 1.73 s vs 0.29 s). Its
bulk insert's forked builder uses its own plain pipe and is not affected.
