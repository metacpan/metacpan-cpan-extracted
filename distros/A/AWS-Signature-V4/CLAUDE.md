# AWS::Signature::V4

A user-agent agnostic implementation of AWS Signature Version 4, for both
the credentials and the X.509 (IAM Roles Anywhere) variants. Pure Perl
5.24 with Moo; `Dist::Zilla` (`[@Milla]`) builds the distribution.

## Running the tests

The dependencies are installed in `local/` by carton, so they have to be
put on the include path:

```shell
prove -l -Ilocal/lib/perl5 t/          # or: carton exec prove -l t/
```

Plain `prove -l t/` dies on `Can't locate Moo.pm`. The same applies to
running anything in `eg/` by hand: `perl -Ilocal/lib/perl5 eg/...`.

## Layout

- `lib/AWS/Signature/V4.pm` is the signing core; `Chunker.pm`,
  `Checksum.pm`, `Credentials.pm`, `X509.pm` and `Error.pm` sit under
  `lib/AWS/Signature/V4/`.
- **The documentation lives in separate `.pod` files** next to the
  modules, not in the `.pm`. A change in behaviour usually needs the
  matching `.pod`, the tests and often an example updated with it.
- `eg/` holds numbered, self-contained example programs, described in
  `eg/README.md`.
- `t/` uses `Test2::V0`.
- `local/` (carton) and `tmp/` (review notes) are git-ignored, as are
  vim's `*.sw*` swap files.

## Conventions

- `unless` is used **only as a statement modifier**. Write the block form
  as `if (!$x) { ... }`: the negated block is harder to read and ages
  badly when an `else` has to be added later.
- Errors are raised with `fail` from `AWS::Signature::V4::Error`, which
  throws an `Ouch`. Code **400** means the caller got the input wrong.
- Examples are self-contained: core modules plus this distribution's own
  dependencies, nothing more. They honour `DRY_RUN=1` (print the signed
  request, send nothing), take credentials from `AWS_ACCESS_KEY_ID`,
  `AWS_SECRET_ACCESS_KEY` and optionally `AWS_SESSION_TOKEN`, ask
  `HTTP::Tiny` for `verify_SSL => 1`, and remove the `host` header
  because `HTTP::Tiny` insists on setting it itself.
- Anything pasted into a URL's host name — a bucket, a region — is
  validated before use: a `/` in it moves the host elsewhere and the
  signed request, session token included, would go there.

## Where the plan lives

`TODO.md` carries the work programme and the reasoning behind decisions
that were hard to settle. Read it before proposing a change to signing
behaviour: some of what looks odd is recorded there as deliberate, with
the evidence.
