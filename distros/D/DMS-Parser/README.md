# DMS-Parser

**[DMS website](https://flo-labs.gitlab.io/pub/dms-webpage/)** ·
[Tier-1 spec](https://flo-labs.gitlab.io/pub/dms-webpage/tier1.html) ·
[Format comparison](https://flo-labs.gitlab.io/pub/dms-webpage/comparison.html) ·
[Dialects](https://flo-labs.gitlab.io/pub/dms-webpage/dialects.html)

Pure-Perl parser and emitter for [DMS](https://gitlab.com/flo-labs/pub/dms) — a
config and data format with strong typing, insertion-ordered maps, multi-line
heredocs, and optional front-matter metadata.

## Install

```sh
cpanm DMS::Parser
```

Or from source:

```sh
perl Makefile.PL && make && make test && make install
```

## Synopsis

```perl
use DMS::Parser;
use DMS::Parser::Emitter;

# Decode DMS source → Perl value tree
my $src = do { local $/; <STDIN> };
my $doc = DMS::Parser::decode($src);   # returns hashref / arrayref / scalar

# Keep front-matter, comments, and original literal forms for round-trip
my $full = DMS::Parser::decode_document($src);
print DMS::Parser::Emitter::encode($full);   # byte-stable round-trip

# Lite mode — fastest, skips comment/form tracking
my $body = DMS::Parser::decode_lite($src);

# Tier-1 parse (decorator-aware)
my $t1 = DMS::Parser::decode_t1($src);
# $t1->{body}, $t1->{imports}, $t1->{decorators}
```

## Modules

| Module | Purpose |
|---|---|
| `DMS::Parser` | Main parser — `decode`, `decode_document`, `decode_t1` |
| `DMS::Parser::Emitter` | Emitter — `encode` (round-trip), `encode_lite` (canonical) |
| `DMS::Parser::Tier1` | Tier-1 helpers: sigil lexer, import extractor, decorator scanner |

## Type sentinels

DMS scalars without a clean Perl analogue are returned as blessed scalar refs:
`DMS::Parser::Bool`, `Integer`, `Float`, `LocalDate`, `LocalTime`,
`LocalDateTime`, `OffsetDateTime`, `UnorderedTable`.

## Spec

- **Website:** <https://flo-labs.gitlab.io/pub/dms-webpage/>
- **Language specification:** <https://gitlab.com/flo-labs/pub/dms>
- **Tier-1 spec:** <https://flo-labs.gitlab.io/pub/dms-webpage/tier1.html>
- **Format comparison:** <https://flo-labs.gitlab.io/pub/dms-webpage/comparison.html>
- **Dialects index:** <https://flo-labs.gitlab.io/pub/dms-webpage/dialects.html>

For a ~20× faster XS backend see
[DMS-Parser-XS](https://metacpan.org/dist/DMS-Parser-XS).

## License

Dual-licensed under the **Apache License 2.0** and the **MIT license**, at your
option. See `vendor/dms-c/LICENSE-APACHE` and `vendor/dms-c/LICENSE-MIT`.
