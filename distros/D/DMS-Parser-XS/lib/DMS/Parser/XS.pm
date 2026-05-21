package DMS::Parser::XS;
# XS parser — thin Perl shim over the C DMS parser.
#
# Public API mirrors DMS::Parser (pure Perl) so the two backends are drop-in
# interchangeable. SPEC v0.14 names:
#
#     decode($src)            -> body
#     decode_document($src)   -> { meta, body, comments, original_forms }
#     encode($doc)            -> DMS source
#     encode_lite($doc)       -> canonical DMS source
#
# Old names (parse, parse_document, to_dms, to_dms_lite, ...) remain as
# deprecated aliases for one release; they emit a one-time Carp warning
# and forward to the new canonical sub.
#
# Value types returned follow the same conventions as the pure-Perl parser:
# strings are unblessed Perl scalars; booleans, integers, floats, and
# date/time values are blessed into the DMS::* sentinel classes defined by
# DMS::Parser. Maps are Tie::IxHash-tied hashrefs; lists are arrayrefs.

use strict;
use warnings;
use Carp ();
# Tie::IxHash is loaded lazily by Parser.xs on first full-mode parse
# (via load_module inside new_ixhash_fast). Lite-mode-only callers
# never trigger that load and skip the ~7 ms Tie::IxHash.pm parse.
# Full-mode users get the same Document shape as before — Tie::IxHash
# methods are defined by the time `parse_document` returns the tied
# hash, so `keys %$h` etc. work normally.

our $VERSION = '0.5.3';

# Capability flag — this port ships lite-mode decode + lite-mode encode_lite.
# See SPEC §Parsing modes — full and lite.
our $SUPPORTS_LITE_MODE = 1;

# Capability flag — this port ships unordered-table parse mode.
# See SPEC §Unordered tables.
our $SUPPORTS_IGNORE_ORDER = 1;

require XSLoader;
XSLoader::load('DMS::Parser::XS', $VERSION);

# Capture the XSUBs under private aliases so we can redefine the public
# `parse_*` names as deprecated Carp::carp wrappers below. The XSUBs
# themselves are bound under their original names by the XS module
# (renaming them at the C level would require a recompile and break
# any old DLL on disk); aliasing into `_xsub_*` lets us reach them
# without recursion. SPEC v0.14 rename: parse_* → decode_*.
{
    no strict 'refs';
    *_xsub_parse_document      = \&parse_document;
    *_xsub_parse_document_lite = \&parse_document_lite;
}

# Sentinel classes. These mirror DMS::Parser's (pure-Perl) classes so that
# encoders and tests work against both backends unchanged. We define them
# only if pure-Perl DMS::Parser hasn't already been loaded — otherwise we
# inherit its definitions and stay compatible.
sub _ensure_classes {
    return if defined &DMS::Parser::LocalDate::new;
    no strict 'refs';
    # Typed sentinels are blessed scalar refs (one alloc per value instead
    # of the three in a blessed-hash shape). Matches the pure-Perl parser.
    for my $cls (qw(DMS::Parser::LocalDate DMS::Parser::LocalTime DMS::Parser::LocalDateTime
                    DMS::Parser::OffsetDateTime)) {
        *{"${cls}::new"}   = sub { my $v = "$_[1]"; bless \$v, $_[0] };
        *{"${cls}::value"} = sub { ${ $_[0] } };
    }
    *DMS::Parser::Float::new      = sub { my $v = 0 + $_[1]; bless \$v, $_[0] };
    *DMS::Parser::Float::value    = sub { ${ $_[0] } };
    *DMS::Parser::Integer::new    = sub { my $v = 0 + $_[1]; bless \$v, $_[0] };
    *DMS::Parser::Integer::value  = sub { $_[0] };
    *DMS::Parser::Integer::bstr   = sub { "${ $_[0] }" };   # force stringification
    *DMS::Parser::Integer::is_neg = sub { ${ $_[0] } < 0 };
    *DMS::Parser::Bool::new       = sub { my $v = $_[1]?1:0; bless \$v, $_[0] };
    *DMS::Parser::Bool::value     = sub { ${ $_[0] } };
    # Path-segment marker for list-index breadcrumb steps in the
    # attached-comment AST. String keys remain plain scalars.
    *DMS::Parser::Index::new      = sub { my $v = 0 + $_[1]; bless \$v, $_[0] };
    *DMS::Parser::Index::value    = sub { ${ $_[0] } };
    # SPEC §"Unordered tables": marker class for body tables produced by
    # the *_unordered entry points. Underlying storage is a plain Perl
    # hashref (no Tie::IxHash). `to_dms` (full mode) refuses to round-trip
    # a Document containing this variant; `to_dms_lite` accepts it.
    *DMS::Parser::UnorderedTable::new = sub {
        my ($class, $h) = @_;
        $h = {} unless defined $h;
        return bless $h, $class;
    };
}
_ensure_classes();

package DMS::Parser::XS;

# SPEC §Decode/Encode (v0.14): canonical entry point. Returns the body
# only — meta and comments are dropped. Use decode_document() to keep
# them.
sub decode {
    my ($src) = @_;
    my $doc = decode_document($src);
    return $doc->{body};
}

# SPEC §Parsing modes — full and lite. Body-only lite decode.
sub decode_lite {
    my ($src) = @_;
    return decode_document_lite($src)->{body};
}

# SPEC §Front-matter-only decode. Returns the FM table as a hashref
# (lite-mode shape — sidecar order list at "\0__dms_keys"), or undef
# when the document has no front matter at all. Body bytes after the
# closing `+++` are NOT tokenized; bad-body documents with valid FM
# succeed.
#
# Implementation: pre-scan the source in pure Perl to locate the FM
# block (or determine its absence), truncate the input to bytes 0..end-
# of-closing-`+++`-line, and hand the truncated buffer to the C parser
# (`parse_document_lite`). Diagnostics inside the FM block are byte-
# identical to a full decode because the leading bytes (and therefore
# every line / column inside the block) are unchanged.
sub decode_front_matter {
    my ($src) = @_;
    my ($state, $close_end) = _scan_front_matter_bounds($src);
    if ($state eq 'no_fm') {
        return undef;
    }
    my $sub;
    if ($state eq 'unterminated') {
        # Hand the original source straight to the C parser; it will
        # reach EOF inside the FM scan and raise the canonical
        # "unterminated front matter" error.
        $sub = $src;
    } else {  # 'fm'
        # Truncate to end-of-closing-`+++`-line. The C parser then has
        # the complete FM block and an empty body; no body bytes get
        # tokenized, so body errors can't surface. Line/column numbers
        # inside the FM are byte-identical to a full decode.
        $sub = substr($src, 0, $close_end);
    }
    my $doc = _xsub_parse_document_lite($sub);
    return $doc->{meta};
}

# Pre-scan to find the front matter delimiters. Returns one of:
#   ('no_fm',       undef)        — no opening `+++` after trivia
#   ('fm',          $end_offset)  — open + close found; $end_offset is
#                                    the byte offset just past the EOL
#                                    that ends the closing `+++` line
#   ('unterminated',undef)        — open found, no close
#
# Trivia recognized: blank lines (incl. CRLF), `# ...` line comments,
# `// ...` line comments, `### ... ###` block comments, `/* ... */`
# block comments. The scan only needs to be precise enough to locate
# `+++` reliably; it doesn't validate trivia content (the C parser
# will catch any malformed trivia when it re-scans the same prefix).
sub _scan_front_matter_bounds {
    my ($src) = @_;
    my $len = length($src);
    my $i = 0;
    while ($i < $len) {
        my $c = substr($src, $i, 1);
        # Inline whitespace.
        if ($c eq ' ' || $c eq "\t") { $i++; next; }
        # EOL.
        if ($c eq "\n")     { $i++; next; }
        if ($c eq "\r") {
            $i += (substr($src, $i, 2) eq "\r\n") ? 2 : 1;
            next;
        }
        # `### ... ###` block comment.
        if (substr($src, $i, 3) eq '###') {
            my $end = index($src, "###", $i + 3);
            return ('no_fm', undef) if $end < 0;
            $i = $end + 3;
            next;
        }
        # `# ...` line comment.
        if ($c eq '#') {
            my $nl = index($src, "\n", $i);
            $i = $nl < 0 ? $len : $nl + 1;
            next;
        }
        # `// ...` line comment.
        if ($c eq '/' && substr($src, $i, 2) eq '//') {
            my $nl = index($src, "\n", $i);
            $i = $nl < 0 ? $len : $nl + 1;
            next;
        }
        # `/* ... */` block comment.
        if ($c eq '/' && substr($src, $i, 2) eq '/*') {
            my $end = index($src, '*/', $i + 2);
            return ('no_fm', undef) if $end < 0;
            $i = $end + 2;
            next;
        }
        last;
    }
    # Now check for `+++` opener on its own line.
    return ('no_fm', undef) if $i + 3 > $len;
    return ('no_fm', undef) if substr($src, $i, 3) ne '+++';
    my $j = $i + 3;
    # Optional trailing inline whitespace, then EOL or EOF.
    while ($j < $len) {
        my $c = substr($src, $j, 1);
        last if $c ne ' ' && $c ne "\t";
        $j++;
    }
    if ($j < $len) {
        my $c = substr($src, $j, 1);
        if ($c ne "\n" && $c ne "\r") {
            # `+++` followed by other content on same line is not an
            # opener (per SPEC §Front matter).
            return ('no_fm', undef);
        }
    }
    # Search for the closing `+++` line. Each candidate must be `+++`
    # on its own line, optionally surrounded by inline whitespace.
    # We walk line-by-line starting from `$j` (the EOL after the open).
    my $p = $j;
    while ($p < $len) {
        # Skip the EOL we're sitting on.
        my $c = substr($src, $p, 1);
        if ($c eq "\n") { $p++; }
        elsif ($c eq "\r") {
            $p += (substr($src, $p, 2) eq "\r\n") ? 2 : 1;
        }
        last if $p >= $len;
        # Find end of this line.
        my $line_start = $p;
        my $nl = index($src, "\n", $p);
        my $line_end = $nl < 0 ? $len : $nl;
        # If line_end - 1 is `\r`, the line proper ends one before.
        my $line_end_no_cr = $line_end;
        if ($line_end > $line_start
            && substr($src, $line_end - 1, 1) eq "\r") {
            $line_end_no_cr = $line_end - 1;
        }
        my $line = substr($src, $line_start, $line_end_no_cr - $line_start);
        my $trimmed = $line;
        $trimmed =~ s/^[ \t]+//;
        $trimmed =~ s/[ \t]+$//;
        if ($trimmed eq '+++') {
            # Include the EOL after the closing `+++` in the truncated
            # range, so the C parser sees a complete line.
            my $close_end = $nl < 0 ? $len : $nl + 1;
            return ('fm', $close_end);
        }
        $p = $line_end;  # advance to the EOL position
    }
    return ('unterminated', undef);
}

# decode_document and decode_document_lite forward to the XS-defined
# subs (still bound under their original names in Parser.xs, captured
# above as _xsub_parse_document / _xsub_parse_document_lite). The
# rename happens Perl-side so DMS-XS keeps loading any existing .dll
# without a rebuild.
sub decode_document      { goto &_xsub_parse_document }
sub decode_document_lite { goto &_xsub_parse_document_lite }

# Re-emit a parsed Document as DMS source. See SPEC §encode.
#
# Note: the underlying C parser does not yet record `original_forms`
# (integer-base / string-form preservation lives in the pure-Perl port).
# When `original_forms` is missing, the emitter falls back to defaults:
# integers render as canonical decimal, strings as basic-quoted. Comments
# and data structure are preserved via the C parser's existing comment AST.
sub encode {
    my ($doc) = @_;
    require DMS::Parser::Emitter;
    return DMS::Parser::Emitter::encode($doc);
}

# Lite-mode emit: canonical DMS source — no comments, decimal integers,
# basic-quoted strings — ignoring any comments / original_forms in $doc.
# `decode(encode_lite($doc))` is data-equivalent to $doc; round-trip of
# comment + literal-form is *not* preserved. SPEC §encode.
#
# Implemented entirely in Perl (DMS::Parser::Emitter is shared between the
# pure-Perl and XS backends — same Document shape, same walk).
sub encode_lite {
    my ($doc) = @_;
    # Fast path: C-side lite emitter walks the Perl tree and writes DMS
    # bytes directly. Skips the per-kvpair Perl-VM trips of the pure-Perl
    # Emitter. Falls back to the pure-Perl path when the XS function
    # isn't available (older builds) or when the document contains a
    # DMS::Parser::UnorderedTable that the C path doesn't yet handle specially
    # — for the bench's normalized fixture, this is the path.
    if (defined &encode_lite_xs) {
        return encode_lite_xs($doc);
    }
    if (defined &to_dms_lite_xs) {
        # Backward compat — pre-rebuild XS exposes the old XSUB name.
        return to_dms_lite_xs($doc);
    }
    require DMS::Parser::Emitter;
    return DMS::Parser::Emitter::encode_lite($doc);
}

# Deprecated aliases (SPEC v0.14: parse → decode, to_dms → encode).
# Removed in the next release. Each warns once per process via Carp.
{ my $warned;
  sub parse {
      unless ($warned++) {
          Carp::carp(
              'DMS::Parser::XS::parse() is deprecated; use decode() instead. '
            . 'SPEC v0.14 renamed parse() to decode().');
      }
      goto &decode;
  }
}
{ my $warned;
  sub parse_lite {
      unless ($warned++) {
          Carp::carp(
              'DMS::Parser::XS::parse_lite() is deprecated; use decode_lite() instead. '
            . 'SPEC v0.14 renamed parse_lite() to decode_lite().');
      }
      goto &decode_lite;
  }
}
{ my $warned;
  sub to_dms {
      unless ($warned++) {
          Carp::carp(
              'DMS::Parser::XS::to_dms() is deprecated; use encode() instead. '
            . 'SPEC v0.14 renamed to_dms() to encode().');
      }
      goto &encode;
  }
}
{ my $warned;
  sub to_dms_lite {
      unless ($warned++) {
          Carp::carp(
              'DMS::Parser::XS::to_dms_lite() is deprecated; use encode_lite() instead. '
            . 'SPEC v0.14 renamed to_dms_lite() to encode_lite().');
      }
      goto &encode_lite;
  }
}

# Tier-1 decode — fully C-accelerated path.
#
# Calls the C FFI (dms_decode_t1 + dms_t1_doc_to_json) via the XS
# decode_t1_to_json XSUB, then decodes the returned JSON string to
# a native Perl structure. Body values arrive as tagged-scalar hashrefs
# ({"type":"string","value":"Alice"}) matching the encoder.exe output;
# _untag_value converts them to the same native Perl types that
# decode_document returns so callers see a consistent shape.
sub decode_t1 {
    my ($src) = @_;
    require JSON::PP;
    my $json_str = decode_t1_to_json($src);   # XS XSUB — returns UTF-8 string
    my $raw = JSON::PP::decode_json($json_str);
    # Convert tagged body + param-group values to native Perl types.
    $raw->{body} = _untag_value($raw->{body});
    return $raw;
}

# Recursively convert a tagged-scalar or composite JSON value to a native
# Perl type matching what decode_document returns:
#   {"type":"string",  "value":"..."} → plain string scalar
#   {"type":"integer", "value":"..."} → DMS::Parser::Integer blessed scalar-ref
#   {"type":"float",   "value":"..."} → DMS::Parser::Float  blessed scalar-ref
#   {"type":"bool",    "value":"..."} → DMS::Parser::Bool   blessed scalar-ref
#   {"type":"local-date"/"local-time"/"local-datetime"/"offset-datetime",...}
#                                    → appropriate DMS::Parser::* blessed scalar-ref
#   {key=>value,...}                 → hashref with all values recursively untagged
#   [...]                            → arrayref with all items recursively untagged
#   plain scalar                     → returned as-is
sub _untag_value {
    my ($v) = @_;
    return $v unless ref($v);
    if (ref($v) eq 'ARRAY') {
        return [ map { _untag_value($_) } @$v ];
    }
    if (ref($v) eq 'HASH') {
        my $type = $v->{type};
        if (defined $type && exists $v->{value}) {
            my $val = $v->{value};
            if    ($type eq 'string')           { return $val }
            elsif ($type eq 'integer')          { return DMS::Parser::Integer->new($val) }
            elsif ($type eq 'float')            { return DMS::Parser::Float->new($val) }
            elsif ($type eq 'bool')             { return DMS::Parser::Bool->new($val eq 'true' ? 1 : 0) }
            elsif ($type eq 'local-date')       { return DMS::Parser::LocalDate->new($val) }
            elsif ($type eq 'local-time')       { return DMS::Parser::LocalTime->new($val) }
            elsif ($type eq 'local-datetime')   { return DMS::Parser::LocalDateTime->new($val) }
            elsif ($type eq 'offset-datetime')  { return DMS::Parser::OffsetDateTime->new($val) }
        }
        # Plain object (table) — recurse into all values.
        my %out;
        for my $k (keys %$v) {
            $out{$k} = _untag_value($v->{$k});
        }
        return \%out;
    }
    return $v;
}

# Helper matching DMS::Parser::new_table — returns an IxHash-tied hashref.
sub new_table {
    tie my %h, 'Tie::IxHash';
    return \%h;
}

# SPEC §"Unordered tables" — opt-in. The underlying C parser builds
# Tie::IxHash tied tables; rather than fork the C code, we walk the
# returned tree post-parse and replace every body table with a plain
# DMS::Parser::UnorderedTable hashref (insertion-order tracking dropped). Front
# matter is intentionally left alone — meta stays ordered per spec.
sub decode_document_unordered {
    my ($src) = @_;
    my $doc = _xsub_parse_document($src);
    $doc->{body} = _to_unordered($doc->{body}) if defined $doc->{body};
    return $doc;
}

sub decode_lite_document_unordered {
    my ($src) = @_;
    my $doc = _xsub_parse_document_lite($src);
    $doc->{body} = _to_unordered($doc->{body}) if defined $doc->{body};
    return $doc;
}

# Deprecated aliases (SPEC v0.14). Removed in the next release.
# Deprecated wrappers redefining the XSUB-bound `parse_document` /
# `parse_document_lite` in the symbol table. They warn once per process
# and forward to the captured XSUB (no recursion).
{ my $warned;
  no warnings 'redefine';
  *parse_document = sub {
      unless ($warned++) {
          Carp::carp(
              'DMS::Parser::XS::parse_document() is deprecated; '
            . 'use decode_document() instead. '
            . 'SPEC v0.14 renamed parse_document() to decode_document().');
      }
      goto &_xsub_parse_document;
  };
}
{ my $warned;
  no warnings 'redefine';
  *parse_document_lite = sub {
      unless ($warned++) {
          Carp::carp(
              'DMS::Parser::XS::parse_document_lite() is deprecated; '
            . 'use decode_document_lite() instead. '
            . 'SPEC v0.14 renamed parse_document_lite() to decode_document_lite().');
      }
      goto &_xsub_parse_document_lite;
  };
}

{ my $warned;
  sub parse_document_unordered {
      unless ($warned++) {
          Carp::carp(
              'DMS::Parser::XS::parse_document_unordered() is deprecated; '
            . 'use decode_document_unordered() instead. '
            . 'SPEC v0.14 renamed parse_*() to decode_*().');
      }
      goto &decode_document_unordered;
  }
}
{ my $warned;
  sub parse_lite_document_unordered {
      unless ($warned++) {
          Carp::carp(
              'DMS::Parser::XS::parse_lite_document_unordered() is deprecated; '
            . 'use decode_lite_document_unordered() instead. '
            . 'SPEC v0.14 renamed parse_*() to decode_*().');
      }
      goto &decode_lite_document_unordered;
  }
}

# Recursive walk: convert each table (plain or Tie::IxHash-tied hash) to
# a DMS::Parser::UnorderedTable plain hashref. Lists are descended into; blessed
# leaves (DMS::Parser::Integer / Float / Bool / dates) are preserved as-is.
sub _to_unordered {
    my ($v) = @_;
    return $v if !defined $v;
    my $r = ref($v);
    return $v if $r eq '';
    # Blessed sentinels: leaves. (DMS::Parser::UnorderedTable shouldn't appear
    # here at all — the XS parser doesn't produce it — but if it does we
    # leave it.)
    require Scalar::Util;
    if (Scalar::Util::blessed($v)) {
        return $v if $r ne 'DMS::Parser::UnorderedTable';
        # Already unordered — recurse into children for safety.
        my %h;
        for my $k (keys %$v) {
            $h{$k} = _to_unordered($v->{$k});
        }
        return bless \%h, 'DMS::Parser::UnorderedTable';
    }
    if ($r eq 'ARRAY') {
        return [ map { _to_unordered($_) } @$v ];
    }
    if ($r eq 'HASH') {
        # Tie::IxHash-tied hash or plain hash — either way, walk via
        # `keys` (tied yields insertion order; plain yields hash order)
        # and rebuild as a plain blessed UnorderedTable. We drop the
        # Tie::IxHash magic by copying into a fresh `%h`.
        my %h;
        for my $k (keys %$v) {
            $h{$k} = _to_unordered($v->{$k});
        }
        return bless \%h, 'DMS::Parser::UnorderedTable';
    }
    return $v;
}

1;

__END__

=encoding UTF-8

=head1 NAME

DMS::Parser::XS - XS (C-backed) parser for DMS, a data syntax with strong
typing, ordered maps, multi-line heredocs, and front-matter metadata

=head1 SYNOPSIS

  use DMS::Parser::XS;

  my $src = do { local $/; <STDIN> };
  my $doc = DMS::Parser::XS::decode($src);  # hashref / arrayref / scalar / blessed type

  # Full Document (with meta, comments)
  my $full = DMS::Parser::XS::decode_document($src);

  # Lite mode — no comment/form tracking, fastest path
  my $body = DMS::Parser::XS::decode_lite($src);

  # Round-trip encode (pure-Perl emitter, shared with DMS::Parser)
  my $dms = DMS::Parser::XS::encode($full);

  # Fast canonical emit via C-side lite emitter
  my $canonical = DMS::Parser::XS::encode_lite($full);

=head1 DESCRIPTION

DMS::Parser::XS is the XS binding to the C reference parser
(L<https://gitlab.com/flo-labs/pub/dms-c>). It exposes the same public API as
L<DMS::Parser> (pure-Perl) so the two backends are drop-in interchangeable —
the Document shape, type sentinels, and emitter are identical.

Typical speedup versus the pure-Perl parser: ~20x on large documents in lite
mode. The C sources (C<dms.c> / C<dms.h>) plus their utf8proc dependency are
vendored in the tarball under C<vendor/dms-c/>, so no separate C library
installation is required.

=head1 FUNCTIONS

=head2 decode($src)

Decode a DMS source string. Returns the body value tree (same shape as
L<DMS::Parser/decode>).

=head2 decode_document($src)

Like L</decode> but returns a full Document hashref with C<body>, C<meta>,
C<comments>, and C<original_forms>.

=head2 decode_lite($src)

Like L</decode> but skips comment and literal-form tracking. Fastest parse
mode; body values are identical to L</decode>.

=head2 decode_lite_document($src)

Like L</decode_document> but lite mode.

=head2 decode_front_matter($src)

Parse only the front-matter block C<+++ ... +++>. Returns a hashref or
C<undef> when the document has no front matter.

=head2 decode_document_unordered($src)

Like L</decode_document> but converts all body tables to
L<DMS::Parser::UnorderedTable> (plain hashrefs, no insertion-order tracking).

=head2 encode($doc)

Re-emit the Document as DMS source. Delegates to L<DMS::Parser::Emitter>.
Preserves comments and original literal forms.

=head2 encode_lite($doc)

Emit canonical DMS source. Uses the C-side lite emitter when available,
falling back to L<DMS::Parser::Emitter>.

=head2 decode_t1($src)

Decode a tier-1 DMS document (C<_dms_tier: 1> front-matter key). Returns a
hashref with keys C<tier>, C<imports>, C<body>, C<decorators>, and C<_raw_doc>,
matching the shape returned by L<DMS::Parser::Tier1/decode_t1>.

The decorator-scanning and import-validation logic is implemented in pure Perl
(L<DMS::Parser::Tier1>); the tier-0 sub-parse is routed through the XS C parser
for the performance benefit. Dies with C<"line:col: message\n"> on parse or
validation error.

=head1 DEPENDENCIES

Requires a C compiler at build time. The C DMS parser sources and utf8proc
are bundled under C<vendor/dms-c/> — no external C library is needed.

=head1 SEE ALSO

L<DMS::Parser> (pure-Perl backend), L<DMS::Parser::Emitter>,
L<https://gitlab.com/flo-labs/pub/dms> (language spec),
L<https://gitlab.com/flo-labs/pub/dms-c> (C parser)

=head1 AUTHOR

Filip Lopes

=head1 LICENSE

Dual-licensed under the Apache License 2.0 and the MIT license, at your option.

=cut
