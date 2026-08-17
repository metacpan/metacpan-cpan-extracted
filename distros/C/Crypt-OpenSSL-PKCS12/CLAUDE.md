# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`Crypt::OpenSSL::PKCS12` is a Perl XS extension wrapping OpenSSL's PKCS12 API. It supports OpenSSL 1.x, 3.x, and 4.x and is managed via [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla).

The core implementation is split between:
- `PKCS12.xs` — XS/C code that interfaces directly with OpenSSL's libssl/libcrypto
- `PKCS12.pm` — thin Perl wrapper that loads the XS module via `XSLoader`

## Build & Test

**Install dependencies:**
```sh
cpanm --installdeps .
# or using cpanfile directly:
cpanm --cpanfile cpanfile --installdeps .
```

**Build:**
```sh
perl Makefile.PL
make
```

**Run all tests:**
```sh
prove -lr -l -b t
```

**Run a single test:**
```sh
prove -lvb t/pkcs12.t
```

**Author testing** (enables `-Wall -Werror` for gcc):
```sh
AUTHOR_TESTING=1 perl Makefile.PL && make
```
Note: on macOS the `darwin` branch of `maint/Makefile_header.PL` never sets `OPTIMIZE`, so `-Wall -Werror` is silently skipped. This only takes effect on Linux CI.

**Testing against a specific OpenSSL version locally** (macOS/Homebrew): install e.g. `openssl@1.1`, `openssl@3.0`, `openssl@3.5`, `openssl@4` via `brew install`, then point the build at one — `Crypt::OpenSSL::Guess` reads `OPENSSL_PREFIX` directly:
```sh
export OPENSSL_PREFIX=/opt/homebrew/opt/openssl@4
export DYLD_LIBRARY_PATH="$OPENSSL_PREFIX/lib"
perl Makefile.PL && make && prove -lr -l -b t
```
No CI job here builds against OpenSSL 4.0 yet (too new for CI base images) — this is the only way to verify a 4.0-specific fix actually works rather than just compiles in review.

## Architecture

### XS Layer (`PKCS12.xs`)

The XS file does all the heavy lifting:
- Compatibility macros at the top handle API differences between OpenSSL < 1.1.0 and >= 1.1.0
- OpenSSL 3.x requires loading providers (`legacy` and `deflt` globals); this is handled via `#if OPENSSL_VERSION_NUMBER >= 0x30000000L`
- `_load_pkey()` and `_load_cert_chain()` accept either a PEM string (detected by `"----"` prefix) or a file path — this dual-input pattern is used by `create()` and `create_as_string()`
- `CHECK_OPEN_SSL(p_result)` macro wraps OpenSSL calls and croaks with an error message from `ERR_reason_error_string()` on failure
- `certificate()`, `private_key()`, `ca_certificate()` silently return an empty string on wrong password or missing content — the return value of `dump_certs_keys_p12()` is ignored, so these never croak on decryption failure
- `legacy_support()` checks the global `legacy` pointer (set only by constructors); may return false before any object is constructed even if the provider is loadable
- `as_string()` takes no arguments — it serializes the in-memory PKCS12 object directly with no password

### Distribution Management (`dist.ini`)

The distribution uses Dist::Zilla with `MakeMaker::Awesome`. Key points:
- `Makefile.PL` and `cpanfile` are **generated** by `dzil build` — edit `dist.ini` and `maint/Makefile_header.PL` instead, not `Makefile.PL` directly
- Bumping `$VERSION` in `PKCS12.pm` alone is not enough — `Makefile.PL` hardcodes the version from the last `dzil build`/`dzil test`. A stale one causes `object version X does not match bootstrap parameter Y` at runtime; always `dzil build` after a version bump (also regenerates `README.md`). It may also incidentally rewrite `LICENSE`'s GPL boilerplate if the local `Software::License` version differs from whatever last generated it — unrelated noise, safe to revert.
- Version is sourced from `PKCS12.pm` via `[VersionFromMainModule]`
- `README.md` is auto-generated from the POD in `PKCS12.pm`
- Develop-only dependencies (e.g. fixture generation scripts) must be declared in `dist.ini` under `[Prereqs / DevelopRequires]` — adding them directly to `cpanfile` is futile, `dzil build` overwrites it
- Runtime prereqs (including minimum Perl) go in `[Prereqs / RuntimeRequires]`; minimum Perl syntax: `perl = 5.014000`

### Test Certificates (`certs/`)

Tests use pre-generated `.p12` files in `certs/`. Different cert files are used depending on OpenSSL version:
- `test_le_1.1.p12` for OpenSSL ≤ 1.1
- `test.p12` for OpenSSL 3.x

### OpenSSL Version Compatibility

The codebase maintains compatibility across OpenSSL 1.0, 1.1, 3.x, and 4.x via:
- C preprocessor macros aliasing renamed/removed symbols for older versions
- Runtime version checks using `Crypt::OpenSSL::Guess`'s `openssl_version()` in tests
- `changepass` (`PKCS12_newpass()`) is a known-broken upstream API for PBES2-encrypted
  PKCS12 files (the default on OpenSSL 3.x/4.x) — see
  [openssl/openssl#19092](https://github.com/openssl/openssl/issues/19092) and
  [#62](https://github.com/dsully/perl-crypt-openssl-pkcs12/issues/62). Only OpenSSL 1.x
  is confirmed working; the test suite skips it everywhere else (`t/pkcs12.t`,
  `t/pkcs12-string.t`, `t/pkcs12-from-scratch.t`)

## Release

**Build tarball:**
```sh
dzil build
```

**Upload to CPAN** (`dzil release` requires an interactive TTY for `ConfirmRelease`; run it in a real terminal or use the alternative):
```sh
dzil release          # interactive terminal only — prompts y/n
cpan-upload Crypt-OpenSSL-PKCS12-<VERSION>.tar.gz   # non-interactive alternative
```

**Trial release** (e.g. to solicit CPAN Testers coverage before committing to stable): `dzil release --trial` uploads as `Crypt-OpenSSL-PKCS12-<VERSION>-TRIAL.tar.gz` — PAUSE indexes it as non-default without needing an underscore in `$VERSION`. Tag normally (`v<VERSION>`, no `-TRIAL` suffix) so the same commit can later be promoted to a real release with no changes.

**GitHub release** (use `--notes`, not `--body`):
```sh
gh release create v<VERSION> --title "..." --notes "..."
```

## CI

GitHub Actions workflows in `.github/workflows/` test against Linux (Perl 5.14–5.36), macOS, Windows (Strawberry Perl), Cygwin, and MSYS2/MinGW. The Linux workflow is the canonical reference for the build/test steps.

**Workflow security (zizmor):** `zizmor .github/workflows/` audits Actions workflows locally and should report 0 findings under the default persona (`--pedantic` surfaces extra style findings; `--fix=safe` / `--fix=all` applies automated fixes). `.github/workflows/zizmor.yml` runs it in CI and uploads results to the Security tab as SARIF — it does not fail the build on findings. Pin third-party actions to a commit SHA via `git ls-remote https://github.com/<owner>/<repo> refs/tags/<tag>` (peel annotated tags with `refs/tags/<tag>^{}` to get the commit, not the tag object) — comment with the specific immutable tag (e.g. `v2.32.0`), never a moving major alias (`v2`), since majors get repointed as new releases ship.

**Dependabot:** `.github/dependabot.yml` tracks only the `github-actions` ecosystem.

## GitHub CLI Tips

**Fetching inline PR review comments** (per-line, not top-level review summaries):
```sh
gh api repos/dsully/perl-crypt-openssl-pkcs12/pulls/{pr}/comments   # inline comments
gh pr view {pr} --json reviews                                        # top-level summaries only
```

**Remotes:** `origin` is the canonical repo (dsully/perl-crypt-openssl-pkcs12) — push branches and open PRs against it. `timlegge` is an unrelated personal fork remote also configured on this checkout.
