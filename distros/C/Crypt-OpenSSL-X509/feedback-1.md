I reviewed your Claude review with Claude and it produces a fixed patch as attached.

Thanks — the review is right on the substance, and I've revised the patch.
Summary of what I took, plus one important caveat where following the
review verbatim would introduce a new bug.

Adjudication of the six items:

- Bug 1 (error path re-introduces the OOB) — VALID, fixed. Confirmed:
  forcing `r = 0`, `malloc(1)`, then a second `OBJ_obj2txt(key, 1, ...)`
  still returns the full OID length, which then reached `hv_store` as the
  key length — an over-read of the 1-byte buffer.

- Bug 2 (`key` leaks when `hv_store` fails) — VALID, fixed. The `free(key)`
  now runs before the failure `croak`, so it is not skipped by the longjmp.

- Bug 3 (`rv` SV leaks on croak paths) — the observation is VALID, but
  please DO NOT apply the recommended `sv_2mortal(rv)` fix. `hv_store()`
  takes ownership of `rv` without incrementing its refcount (that is why
  the original code passes it non-mortal). If `rv` is also mortalised, the
  mortal stack and the hash both own the single reference, and the
  scope-end mortal decref frees an SV the hash still holds — a
  use-after-free / double-free on the *success* path. I confirmed this the
  hard way: the corrected patch below (which does NOT mortalise) passes the
  full 96/96 suite; mortalising would crash the extension-enumeration
  tests. The correct leak fix is `SvREFCNT_dec(rv)` only on the error paths
  that croak before `hv_store` adopts it — included below.

- OpenSSL 1.0.x length-probe note — handled without a version macro. The
  patch stores `strlen(key)` (bytes actually written, always <= the
  allocation) as the `hv_store` length rather than any `OBJ_obj2txt` return
  value. That one change removes the over-read on every path at once — the
  original CVE, the Bug 1 error path, and the 1.0.x under-report you noted
  (worst case there is a truncated key, never an over-read).

- Dead `size_t len = 128;` — removed.

Corrected patch (against 2.1.2 X509.xs), which builds clean, passes
`make test` 96/96, and flips the long-OID reproduction from leaking heap
bytes to round-tripping the full OID exactly:

Tim

Revised patch, see: 680-review.md

