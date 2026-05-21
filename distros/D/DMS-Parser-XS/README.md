# DMS-Parser-XS

**[DMS website](https://flo-labs.gitlab.io/pub/dms-webpage/)** ·
[Tier-1 spec](https://flo-labs.gitlab.io/pub/dms-webpage/tier1.html) ·
[Format comparison](https://flo-labs.gitlab.io/pub/dms-webpage/comparison.html) ·
[Dialects](https://flo-labs.gitlab.io/pub/dms-webpage/dialects.html)

XS (C-backed) parser and emitter for [DMS](https://gitlab.com/flo-labs/pub/dms)
— a config and data format with strong typing, insertion-ordered maps,
multi-line heredocs, and optional front-matter metadata.

This distribution wraps the [C reference parser](https://gitlab.com/flo-labs/pub/dms-c)
via XS, delivering roughly **~20× speedup** over the pure-Perl
[DMS-Parser](https://metacpan.org/dist/DMS-Parser) on large documents. The C
sources (including the utf8proc dependency) are vendored under `vendor/dms-c/`,
so no external C library is required — only a C compiler at build time.

## Install

```sh
cpanm DMS::Parser::XS
```

Or from source (requires a C compiler):

```sh
perl Makefile.PL && make && make test && make install
```

## Synopsis

```perl
use DMS::Parser::XS;

# Decode DMS source → Perl value tree (same shape as DMS::Parser)
my $src = do { local $/; <STDIN> };
my $doc = DMS::Parser::XS::decode($src);   # hashref / arrayref / scalar

# Full Document (meta, comments, original_forms)
my $full = DMS::Parser::XS::decode_document($src);

# Lite mode — fastest path, no comment/form tracking
my $body = DMS::Parser::XS::decode_lite($src);

# Emit — delegates to the shared pure-Perl emitter
use DMS::Parser::Emitter;
print DMS::Parser::XS::encode($full);        # round-trip
print DMS::Parser::XS::encode_lite($full);   # canonical
```

## API compatibility

`DMS::Parser::XS` mirrors the `DMS::Parser` API exactly — `decode`,
`decode_document`, `decode_lite`, `decode_lite_document`, `encode`,
`encode_lite`, `decode_front_matter`, `decode_document_unordered`.

## Spec

- **Website:** <https://flo-labs.gitlab.io/pub/dms-webpage/>
- **Language specification:** <https://gitlab.com/flo-labs/pub/dms>
- **Tier-1 spec:** <https://flo-labs.gitlab.io/pub/dms-webpage/tier1.html>
- **Format comparison:** <https://flo-labs.gitlab.io/pub/dms-webpage/comparison.html>
- **Dialects index:** <https://flo-labs.gitlab.io/pub/dms-webpage/dialects.html>
- **C parser:** <https://gitlab.com/flo-labs/pub/dms-c>

## License

Dual-licensed under the **Apache License 2.0** and the **MIT license**, at your
option. See `vendor/dms-c/LICENSE-APACHE` and `vendor/dms-c/LICENSE-MIT`.
