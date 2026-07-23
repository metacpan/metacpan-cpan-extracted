# Cavil::Matcher

[![CI](https://github.com/openSUSE/cavil-matcher/actions/workflows/ci.yml/badge.svg)](https://github.com/openSUSE/cavil-matcher/actions/workflows/ci.yml)

The next-generation license pattern matcher for [Cavil](https://github.com/openSUSE/cavil).

Cavil scans whole Linux distributions to find and identify license text. `Cavil::Matcher` is the engine
that turns source files into license and keyword matches. It keeps the proven token-hash prefix-tree
algorithm of its predecessor ([`Spooky::Patterns::XS`](https://github.com/openSUSE/Spooky-Patterns-XS)) but
rebuilds everything around it so the engine scales operationally:

- **Adding or removing a pattern never rebuilds the whole cache.** The compiled index is a set of immutable
  *segments* plus a small *manifest*; a new pattern compiles one small segment, a removed pattern is just a
  tombstone.
- **One shared copy per host.** Segments are memory-mapped read-only and queried in place, so a fleet of
  index workers shares a single physical copy instead of each loading its own — attaching a 50 MB index to
  25 workers costs kilobytes of private memory, not gigabytes.
- **Resolving many matches stays fast.** A file that produces a great many matches — keyword-heavy or highly
  repetitive source — took time quadratic in the match count to resolve in the previous engine; here that
  step is near-linear, for identical results.
- **A versioned, checksummed on-disk format** with a fully validated reader: a corrupt or hostile segment is
  rejected, never mis-read.
- **Rock-solid on any input.** Scanning a distribution means ingesting binaries, malware test corpora and
  malformed files; the matcher never crashes.

Most of the code — the whole segment/manifest lifecycle — is readable Perl. Only the per-file scan and hashing
live in a small, frozen C++ core, kept bit-for-bit compatible with the previous engine so switching needs no
database migration.

See [`docs/Architecture.md`](docs/Architecture.md) for the full design and rationale.

## Install

```
perl Makefile.PL
make
make test
sudo make install
```

Requires a 64-bit Perl (token hashes are 64-bit), a C++17 compiler (`g++`), and
[`Cpanel::JSON::XS`](https://metacpan.org/pod/Cpanel::JSON::XS).

## Synopsis

```perl
use Cavil::Matcher;
use Cavil::Matcher::Index;

# One-off, in-memory matching
my $m = Cavil::Matcher::init_matcher;
$m->add_pattern(1, Cavil::Matcher::parse_tokens('Permission is hereby granted $SKIP30 to deal'));
my $matches = $m->find_matches('some/source/file.c');   # [[pattern_id, start_line, end_line], ...]

# A persistent, incrementally-updatable index
my $idx = Cavil::Matcher::Index->new(dir => '/var/cache/cavil/index');
$idx->add_segment([[1, 'Permission is hereby granted ...'], [2, 'GNU General Public License ...']]);
$idx->tombstone(1);                       # remove a pattern - no recompile

# strict => 1 fails closed if any active segment is missing/corrupt, so an authoritative scan never runs
# against a partial index (a silent "no match"). Omit it for best-effort/diagnostic use, which skips a
# bad segment and keeps going.
my $engine  = $idx->matcher(strict => 1);   # active segments mmapped; refuses to build a partial matcher
my $results = $engine->find_matches('some/source/file.c');
```

## Layout

```
lib/Cavil/Matcher.pm            Public API + XS loader (Cavil::Matcher, ::Engine, ::Hash, ::Bag)
lib/Cavil/Matcher/Manifest.pm   The index manifest (segments, tombstones, generation) - pure Perl
lib/Cavil/Matcher/Index.pm      Segment lifecycle: add / tombstone / merge / query - pure Perl
Matcher.xs, typemap             The thin Perl<->C++ marshalling boundary
src/                            The frozen C++ core (tokenizer, segment, matcher, bag, SpookyV2)
t/                              Self-contained test suite (100% statement/branch/condition coverage)
t/fixtures/                     Test data: licenses/, text/, snippets/ (real production snippets)
xt/                             Developer-only differential tests vs the previous engine
docs/Architecture.md           Design and rationale, in prose
```

## Testing

On a fresh checkout, generate the `Makefile` first: `perl Makefile.PL && make test`. Thereafter `make test`
runs the self-contained suite (no external engine required). The developer-only differential
tests in `xt/` cross-check byte-for-byte equivalence against `Spooky::Patterns::XS` while both engines
coexist; run them with `prove -b xt/` (they skip if the old engine is not installed).

## License

GPL-2.0-or-later. See [COPYING](COPYING).
