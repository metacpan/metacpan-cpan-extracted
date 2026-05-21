package DMS::XS::Parser;
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

our $VERSION = '0.5.0';

# Capability flag — this port ships lite-mode decode + lite-mode encode_lite.
# See SPEC §Parsing modes — full and lite.
our $SUPPORTS_LITE_MODE = 1;

# Capability flag — this port ships unordered-table parse mode.
# See SPEC §Unordered tables.
our $SUPPORTS_IGNORE_ORDER = 1;

require XSLoader;
XSLoader::load('DMS::XS::Parser', $VERSION);

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
    return if defined &DMS::LocalDate::new;
    no strict 'refs';
    # Typed sentinels are blessed scalar refs (one alloc per value instead
    # of the three in a blessed-hash shape). Matches the pure-Perl parser.
    for my $cls (qw(DMS::LocalDate DMS::LocalTime DMS::LocalDateTime
                    DMS::OffsetDateTime)) {
        *{"${cls}::new"}   = sub { my $v = "$_[1]"; bless \$v, $_[0] };
        *{"${cls}::value"} = sub { ${ $_[0] } };
    }
    *DMS::Float::new      = sub { my $v = 0 + $_[1]; bless \$v, $_[0] };
    *DMS::Float::value    = sub { ${ $_[0] } };
    *DMS::Integer::new    = sub { my $v = 0 + $_[1]; bless \$v, $_[0] };
    *DMS::Integer::value  = sub { $_[0] };
    *DMS::Integer::bstr   = sub { "${ $_[0] }" };   # force stringification
    *DMS::Integer::is_neg = sub { ${ $_[0] } < 0 };
    *DMS::Bool::new       = sub { my $v = $_[1]?1:0; bless \$v, $_[0] };
    *DMS::Bool::value     = sub { ${ $_[0] } };
    # Path-segment marker for list-index breadcrumb steps in the
    # attached-comment AST. String keys remain plain scalars.
    *DMS::Index::new      = sub { my $v = 0 + $_[1]; bless \$v, $_[0] };
    *DMS::Index::value    = sub { ${ $_[0] } };
    # SPEC §"Unordered tables": marker class for body tables produced by
    # the *_unordered entry points. Underlying storage is a plain Perl
    # hashref (no Tie::IxHash). `to_dms` (full mode) refuses to round-trip
    # a Document containing this variant; `to_dms_lite` accepts it.
    *DMS::UnorderedTable::new = sub {
        my ($class, $h) = @_;
        $h = {} unless defined $h;
        return bless $h, $class;
    };
}
_ensure_classes();

package DMS::XS::Parser;

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
    require DMS::Emitter;
    return DMS::Emitter::encode($doc);
}

# Lite-mode emit: canonical DMS source — no comments, decimal integers,
# basic-quoted strings — ignoring any comments / original_forms in $doc.
# `decode(encode_lite($doc))` is data-equivalent to $doc; round-trip of
# comment + literal-form is *not* preserved. SPEC §encode.
#
# Implemented entirely in Perl (DMS::Emitter is shared between the
# pure-Perl and XS backends — same Document shape, same walk).
sub encode_lite {
    my ($doc) = @_;
    # Fast path: C-side lite emitter walks the Perl tree and writes DMS
    # bytes directly. Skips the per-kvpair Perl-VM trips of the pure-Perl
    # Emitter. Falls back to the pure-Perl path when the XS function
    # isn't available (older builds) or when the document contains a
    # DMS::UnorderedTable that the C path doesn't yet handle specially
    # — for the bench's normalized fixture, this is the path.
    if (defined &encode_lite_xs) {
        return encode_lite_xs($doc);
    }
    if (defined &to_dms_lite_xs) {
        # Backward compat — pre-rebuild XS exposes the old XSUB name.
        return to_dms_lite_xs($doc);
    }
    require DMS::Emitter;
    return DMS::Emitter::encode_lite($doc);
}

# Deprecated aliases (SPEC v0.14: parse → decode, to_dms → encode).
# Removed in the next release. Each warns once per process via Carp.
{ my $warned;
  sub parse {
      unless ($warned++) {
          Carp::carp(
              'DMS::XS::Parser::parse() is deprecated; use decode() instead. '
            . 'SPEC v0.14 renamed parse() to decode().');
      }
      goto &decode;
  }
}
{ my $warned;
  sub parse_lite {
      unless ($warned++) {
          Carp::carp(
              'DMS::XS::Parser::parse_lite() is deprecated; use decode_lite() instead. '
            . 'SPEC v0.14 renamed parse_lite() to decode_lite().');
      }
      goto &decode_lite;
  }
}
{ my $warned;
  sub to_dms {
      unless ($warned++) {
          Carp::carp(
              'DMS::XS::Parser::to_dms() is deprecated; use encode() instead. '
            . 'SPEC v0.14 renamed to_dms() to encode().');
      }
      goto &encode;
  }
}
{ my $warned;
  sub to_dms_lite {
      unless ($warned++) {
          Carp::carp(
              'DMS::XS::Parser::to_dms_lite() is deprecated; use encode_lite() instead. '
            . 'SPEC v0.14 renamed to_dms_lite() to encode_lite().');
      }
      goto &encode_lite;
  }
}

# Helper matching DMS::Parser::new_table — returns an IxHash-tied hashref.
sub new_table {
    tie my %h, 'Tie::IxHash';
    return \%h;
}

# SPEC §"Unordered tables" — opt-in. The underlying C parser builds
# Tie::IxHash tied tables; rather than fork the C code, we walk the
# returned tree post-parse and replace every body table with a plain
# DMS::UnorderedTable hashref (insertion-order tracking dropped). Front
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
              'DMS::XS::Parser::parse_document() is deprecated; '
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
              'DMS::XS::Parser::parse_document_lite() is deprecated; '
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
              'DMS::XS::Parser::parse_document_unordered() is deprecated; '
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
              'DMS::XS::Parser::parse_lite_document_unordered() is deprecated; '
            . 'use decode_lite_document_unordered() instead. '
            . 'SPEC v0.14 renamed parse_*() to decode_*().');
      }
      goto &decode_lite_document_unordered;
  }
}

# Recursive walk: convert each table (plain or Tie::IxHash-tied hash) to
# a DMS::UnorderedTable plain hashref. Lists are descended into; blessed
# leaves (DMS::Integer / Float / Bool / dates) are preserved as-is.
sub _to_unordered {
    my ($v) = @_;
    return $v if !defined $v;
    my $r = ref($v);
    return $v if $r eq '';
    # Blessed sentinels: leaves. (DMS::UnorderedTable shouldn't appear
    # here at all — the XS parser doesn't produce it — but if it does we
    # leave it.)
    require Scalar::Util;
    if (Scalar::Util::blessed($v)) {
        return $v if $r ne 'DMS::UnorderedTable';
        # Already unordered — recurse into children for safety.
        my %h;
        for my $k (keys %$v) {
            $h{$k} = _to_unordered($v->{$k});
        }
        return bless \%h, 'DMS::UnorderedTable';
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
        return bless \%h, 'DMS::UnorderedTable';
    }
    return $v;
}

1;
