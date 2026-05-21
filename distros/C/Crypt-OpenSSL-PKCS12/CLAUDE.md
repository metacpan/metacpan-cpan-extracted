# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`Crypt::OpenSSL::PKCS12` is a Perl XS extension wrapping OpenSSL's PKCS12 API. It supports both OpenSSL 1.x and 3.x and is managed via [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla).

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
prove -lr -l -b -I inc t
```

**Run a single test:**
```sh
prove -lv t/pkcs12.t
```

**Author testing** (enables `-Wall -Werror` for gcc):
```sh
AUTHOR_TESTING=1 perl Makefile.PL && make
```

## Architecture

### XS Layer (`PKCS12.xs`)

The XS file does all the heavy lifting:
- Compatibility macros at the top handle API differences between OpenSSL < 1.1.0 and >= 1.1.0
- OpenSSL 3.x requires loading providers (`legacy` and `deflt` globals); this is handled via `#if OPENSSL_VERSION_NUMBER >= 0x30000000L`
- `_load_pkey()` and `_load_cert_chain()` accept either a PEM string (detected by `"----"` prefix) or a file path — this dual-input pattern is used by `create()` and `create_as_string()`
- `CHECK_OPEN_SSL(p_result)` macro wraps OpenSSL calls and croaks with an error message from `ERR_reason_error_string()` on failure

### Distribution Management (`dist.ini`)

The distribution uses Dist::Zilla with `MakeMaker::Awesome`. Key points:
- `Makefile.PL` and `cpanfile` are **generated** by `dzil build` — edit `dist.ini` and `maint/Makefile_header.PL` instead, not `Makefile.PL` directly
- Version is sourced from `PKCS12.pm` via `[VersionFromMainModule]`
- `README.md` is auto-generated from the POD in `PKCS12.pm`

### Test Certificates (`certs/`)

Tests use pre-generated `.p12` files in `certs/`. Different cert files are used depending on OpenSSL version:
- `test_le_1.1.p12` for OpenSSL ≤ 1.1
- `test.p12` for OpenSSL 3.x

### OpenSSL Version Compatibility

The codebase maintains compatibility across OpenSSL 1.0, 1.1, and 3.x via:
- C preprocessor macros aliasing renamed/removed symbols for older versions
- Runtime version checks using `Crypt::OpenSSL::Guess`'s `openssl_version()` in tests
- Some features (e.g., `changepass`) are skipped on OpenSSL 3.x due to upstream limitations

## CI

GitHub Actions workflows in `.github/workflows/` test against Linux (Perl 5.14–5.36), macOS, Windows (Strawberry Perl), Cygwin, and MSYS2/MinGW. The Linux workflow is the canonical reference for the build/test steps.
