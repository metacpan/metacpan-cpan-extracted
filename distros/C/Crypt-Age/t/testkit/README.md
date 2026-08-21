# age test kit vectors

The 143 files in `vectors/` are a verbatim copy of the `age/testdata` directory
from the [C2SP/CCTV](https://github.com/C2SP/CCTV) repository (Common Cryptographic
Test Vectors), the canonical home of the age test kit advertised at
<https://age-encryption.org/testkit>.

- **Source**: `github.com/C2SP/CCTV`, path `age/testdata`
- **Commit**: `1e3d2860d46e94e777e1b17c7a6f2436387e3ecc` (2026-06-05) — the commit
  that last touched `age/testdata` as of this import, per `git log -- age/testdata`
  in the upstream repository.
- **License**: 0BSD / CC0-1.0 / Unlicense, author's choice (see `age/README.md` in
  the upstream repository). All three permit copying without attribution; this
  file exists for provenance and update tracking, not because the license
  requires it.
- **Import method**: a plain file copy (`cp age/testdata/* t/testkit/vectors/`),
  not `git subtree`. The vectors are static test data, not code this repo
  develops against, so subtree history would only add noise. This file is the
  provenance record in its place.

Each vector is documented in full by `age/README.md` in the upstream repository
(the "Test file format" section). Summary: a plain-text header of `key: value`
lines, a blank line, then an age-encrypted file (optionally zlib-compressed).
The `expect` key says what should happen when decrypting; the `payload` key is
the hex SHA-256 of all plaintext that must have been released to the
application, even on a failure partway through.

The runner is `t/07-testkit.t`. It does not attempt every vector: recipient
types this distribution does not implement (`scrypt`, `mlkem768x25519`) and
ASCII-armored input are skipped, loudly, with a per-vector reason — see that
file's own header comment for exactly which vectors run, which are skipped and
why, and the known, named exceptions that currently fail against this
distribution's actual behaviour.

## Updating

1. Re-clone or update a checkout of `https://github.com/C2SP/CCTV`.
2. Note the current commit: `git log -1 --format=%H -- age/testdata`.
3. Replace the contents of `vectors/`: `rm -f vectors/*` (this directory only
   ever holds the upstream copy — nothing here is hand-edited) then
   `cp <clone>/age/testdata/* vectors/`.
4. Update the commit SHA and date in this file.
5. Run `prove -lv t/07-testkit.t` and compare the pass/skip/fail tally against
   the previous run. A new vector name that isn't covered by the runner's skip
   or known-failure logic will show up as a new, unclassified result — read
   `age/README.md`'s "Test file format" section again if the vector format
   itself changed.
