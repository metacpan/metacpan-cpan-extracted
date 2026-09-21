# TODO

## Baseline code review

No full code review has ever been done: the first one covered only the
`main...moo` diff (Moo and Ouch), and the security review only looked for
ways to abuse the code, not for correctness. To stay within usage limits,
the review is split in chunks, one per session, in order of priority.

For each chunk:

- start a new session (or `/clear`) first;
- run `/code-review <level>`, naming the files in scope and saying that
  other files may be read for context but only the chunk is reported on,
  e.g. `/code-review high` "review lib/AWS/Signature/V4/Chunker.pm,
  Checksum.pm and their tests t/streaming.t, t/trailer.t; read other files
  only for context";
- have the findings saved to `tmp/review-<n>-<name>.md` (`tmp/` is
  git-ignored), so that nothing is lost between sessions;
- fix after each chunk, or collect all the findings first and fix them
  together.

Chunks 1 to 3 cover all the code: stopping after them already gives a
baseline for everything that runs.

- [x] **1. Signing core** (level `max`, ~890 lines):
      `lib/AWS/Signature/V4.pm` with `t/canonical.t`, `t/basic.t`,
      `t/presign.t`. Canonical request, encoding, presign,
      `encoded_length`.
- [x] **2. Streaming** (level `high`, ~440 lines):
      `lib/AWS/Signature/V4/Chunker.pm`, `Checksum.pm` with
      `t/streaming.t`, `t/trailer.t`.
- [x] **3. Variants and errors** (level `high`, ~760 lines):
      `lib/AWS/Signature/V4/X509.pm`, `Credentials.pm`, `Error.pm` with
      `t/chain.t`, `t/variants.t`, `t/error.t`, `t/errors.t`,
      `t/security.t`. DER parsing, key loading.
- [x] **4. Documentation** (level `medium`, ~1140 lines): all the `.pod`
      files, checked against the code: do they promise anything that the
      code does not do?
- [x] **5. Examples** (level `medium` or `low`, ~670 lines): `eg/*.pl`,
      `eg/README.md`. Lowest priority, can be skipped.

## Fixing the review findings

The findings are in `tmp/review-1-signing-core.md` to
`tmp/review-5-examples.md`. Fix them one file at a time, in the same order
as the review: later areas depend on earlier ones, and a fix in the code
often needs matching changes in the POD, the tests and `eg/`.

Model: Opus 5 at high effort (or xhigh) by default. Switch with `/model`
before a chunk when useful:

- Sonnet 5 is enough for chunks 4 and 5 (wording, error checks,
  comments), at a lower cost;
- Fable 5.1 (twice the cost of Opus 5) only if a fix in chunk 1 turns out
  to be hard and Opus's first attempt does not hold up;
- not Haiku: too easy to miss something in signing code.

For each chunk:

- start a new session (or `/clear`) first;
- ask to fix the findings in `tmp/review-<n>-<name>.md`, updating the
  POD, tests and examples affected by each fix;
- run the test suite and make sure it passes. The dependencies are
  installed in `local/` (by `carton`), so they have to be added to the
  include path: `prove -l -Ilocal/lib/perl5 t/`, or `carton exec prove -l
  t/`. Plain `prove -l t/` dies on `Can't locate Moo.pm`;
- make one commit per chunk.

- [x] **1. Signing core** (Opus 5, Fable 5.1 if needed):
      `tmp/review-1-signing-core.md`.
- [x] **2. Streaming** (Opus 5): `tmp/review-2-streaming.md`.
- [x] **3. Variants and errors** (Opus 5):
      `tmp/review-3-variants-errors.md`.
- [x] **4. Documentation** (Sonnet 5 or Opus 5):
      `tmp/review-4-documentation.md`.
- [x] **5. Examples** (Sonnet 5 or Opus 5): `tmp/review-5-examples.md`.
      Start with the medium finding in `eg/05-s3-chunked-upload.pl`.
- [x] **6. Final check** (Opus 5): run `/code-review high` on the whole
      diff of the fixes (from `d7b121f`, the last commit before them) to
      catch regressions the fixes introduced.
      `tmp/review-6-final.md`, fixed in `ed8fd99`.

## Before release

- [x] **Confirm the `Content-Encoding` order against a real bucket.**
      Done: S3 in `eu-south-1` accepted it, and the stored metadata shows
      the list was parsed rather than merely tolerated. The control, which
      sent `aws-chunked` alone, came back stored as no `Content-Encoding`
      at all; the real case, which sent `gzip,aws-chunked`, came back
      stored as `gzip`. So S3 strips the `aws-chunked` token from the end
      of the list and keeps what is left, which is what RFC 9110 and
      botocore describe. Both objects round-tripped byte-identical.

      What follows is the question as it stood, kept because it explains
      why the module emits this order and how to ask again if AWS ever
      answers differently.

      With `streaming` and an encoding already set by the caller, `sign`
      emits `gzip,aws-chunked` (`lib/AWS/Signature/V4.pm`, in the
      `$streaming` branch; asserted in `t/streaming.t` and documented in
      `V4.pod` under `sign`). This was the only behaviour in the module
      chosen from indirect evidence rather than from AWS itself, because
      the authorities contradict each other:

      - RFC 9110 §8.4 wants the encodings in the order they were applied,
        and `aws-chunked` is the outermost one, applied to the already
        compressed data: `gzip,aws-chunked`;
      - botocore (`httpchecksum.py`) agrees, appending: `headers
        ["Content-Encoding"] += ",aws-chunked"`;
      - the first review cited the S3 documentation for the opposite
        order, and a boto3 issue reports seeing `aws-chunked,gzip` in
        stored metadata.

      The guess was that S3 strips the `aws-chunked` token from either
      position, so that both orders would be accepted and the point would
      be moot; the run above confirms the stripping, at least from the
      end. It does not say what the other order would do, and there is no
      reason to find out while the module sends this one.

      `eg/10-s3-content-encoding-probe.pl` settled it. It uploads a
      gzipped object with `streaming`, plus a control without any
      `Content-Encoding` so that a rejection can be told apart from a
      wrong bucket, region or set of credentials; it reads both back,
      checks the bytes round-trip, and deletes them again. Run it against
      a bucket that can be written to:

      ```shell
      AWS_REGION=eu-west-1 \
         AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=... \
         ./eg/10-s3-content-encoding-probe.pl my-bucket
      ```

      It exits zero and prints `verdict: S3 accepted gzip,aws-chunked`
      when the order the module sends works, which is what it did. If a
      later run somewhere else has the control accepted and the gzip case
      refused, the order is wrong there: swap the last line of the
      `$streaming` branch in `lib/AWS/Signature/V4.pm` to

      ```perl
      join ',', 'aws-chunked', @encodings;
      ```

      update the sentence under `sign` in `V4.pod` and the two
      `content-encoding` assertions in `t/streaming.t` to match, and run
      the probe again to confirm. The report it prints holds no
      credentials, no `Authorization` header and neither bucket nor key,
      so it is safe to paste into a chat or a bug report.
