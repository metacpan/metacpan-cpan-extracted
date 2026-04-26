# CLAUDE.md

## Project overview

Colon::Config is a Perl XS module that parses colon-separated configuration files (like `/etc/passwd`).
It provides a fast C parser with a pure Perl fallback (`read_pp`) for environments where XS compilation fails.

- CPAN distribution: `Colon-Config`
- Perl package: `Colon::Config`
- MIN_PERL_VERSION: 5.010
- Default branch: `master`
- Upstream: `atoomic/Colon-Config`

## Build and test

```bash
perl Makefile.PL && make          # Build XS extension
make test                          # Run all tests
prove -b t/                        # Run tests via prove (use -b for blib, not -l)
prove -b t/basic.t                 # Run a single test
```

After editing `Config.xs`, always rebuild with `make` before running tests.
After editing `lib/Colon/Config.pm`, rebuild with `make` (blib copy must be refreshed).

## Architecture

### XS implementation (`Config.xs`)

The core parser is `_parse_string_field()` — a single-pass state machine that scans the input
string character by character. Key states: `found_eol` (at line start), `found_comment` (inside
comment), `found_sep` (separator count for field extraction).

Values are extracted via pointer ranges (`start_key`/`end_key`, `start_val`/`end_val`) and
copied with `newSVpvn_flags`. This means raw bytes between pointers are preserved even if the
state machine "skips" certain characters (like `\r`) via `continue`.

The `__PARSE_STRING_LINE_FIELD` macro handles end-of-line processing and is reused for
last-line handling (input without trailing newline).

### Pure Perl fallback (`lib/Colon/Config.pm`)

`read_pp()` provides identical behavior to the XS `read()`. When modifying either implementation,
always verify parity using `t/read-pp-field.t` and the XS test suite.

`read_as_hash()` is a convenience wrapper that converts the flat arrayref from `read()` into a hashref.

### Parsing rules

- `:` is the key/value separator
- `#` at line start (after optional whitespace) marks a comment; `#` inside values is literal
- Leading spaces and tabs on keys are stripped; spaces and tabs around values are stripped
- `\r` is skipped for state transitions but preserved in value byte ranges
- `\0` (NUL) is skipped in XS via `continue`
- Lines without `:` are ignored; lines with empty keys (`:value`) are skipped

## XS development guidelines

### C89 compliance

`Config.xs` must compile under C89 (required for Perl 5.10 era compilers):
- All variable declarations must precede executable statements in a block
- No `//` comments in production code (use `/* */`)
- Verify: `cc -std=c89 -pedantic -Wdeclaration-after-statement Config.c`
  (ignore warnings from Perl headers — only check warnings from `Config.c`)

### Thread safety (pTHX_)

Any helper function that calls Perl API macros (`newAV`, `av_push`, `SvCUR`, `croak`, etc.)
must include `pTHX_` in its prototype and be called with `aTHX_`:

```c
SV* my_helper(pTHX_ SV *input);       /* prototype */
result = my_helper(aTHX_ sv);          /* call site */
```

Without `pTHX_`, compilation fails on threaded perls where `MULTIPLICITY` is defined.

### STRLEN type safety

- `SvCUR()` returns `STRLEN` (which is `size_t`, 64-bit on LP64) — never store in `int`
- `newSVpvn_flags()` second argument is `STRLEN` — cast pointer differences to `(STRLEN)`
- For length checks, prefer pointer comparison (`end > start`) over integer cast

### Numeric input validation

- `SvIOK()` only returns true for SVs with internal integer representation — string numerics
  like `"1"` fail the check
- Use `looks_like_number()` for validating numeric input from Perl callers

### ppport.h

The `ppport.h` file (from `Devel::PPPort`) provides backward-compatible macros. Currently
needed for `newSVpvn_flags` on older perls. Include via:

```c
#define NEED_newSVpvn_flags
#include "ppport.h"
```

## XS/PP parity

The pure Perl implementation must produce byte-identical output to XS for all inputs.
Key differences to watch:

- Perl's `\s` matches `\r`, `\n`, `\f`, `\v` — XS only treats space (`0x20`) and tab (`0x09`)
  as whitespace. Use explicit `[ \t]` character classes, never `\s`.
- Perl's `split` handles empty fields differently from C pointer arithmetic.
- XS skips entries with empty keys (`end_key == start_key`); PP must `next unless length $key`.

## Testing

- Test framework: `Test2::Bundle::Extended`, `Test2::Tools::Explain`, `Test2::Plugin::NoWarnings`
- `t/read-pp-field.t` — XS/PP parity tests (compares both implementations with same inputs)
- `t/edge-cases.t` — boundary conditions, empty inputs, whitespace, `\r` handling
- `t/comment-in-value.t` — `#` behavior (comment vs literal in values)
- `t/passwd-read.t` — real-world `/etc/passwd` parsing with field extraction
- `t/use-field.t` — field-based extraction (`$field` argument)
- `t/backslash-r.t` — line ending variants (LF, CRLF, mixed)
- `t/error-messages.t` — error message namespace verification
- `t/utf-8.t` — UTF-8 key/value handling

## CI

GitHub Actions (`.github/workflows/ci.yml`):
- Linux: all Perl versions from 5.10 to devel (via `perldocker/perl-tester`)
- macOS: system Perl
- Windows: Strawberry Perl

Test dependencies are in `.github/cpanfile`.

## Packaging

Uses Dist::Zilla (`dist.ini`) for CPAN releases. `Makefile.PL` is auto-generated by dzil
and checked into the repo for CI compatibility. Do not edit `Makefile.PL` directly.
