package DMS::Parser::Emitter;
# DMS encode emitter — re-emit a parsed Document as DMS source.
#
# Mirrors the Rust reference (language/rust/crates/dms/src/lib.rs::encode).
# Pure Perl; no parser dependency at parse time. Used by both
# DMS::Parser::encode and DMS::Parser::XS::encode — the document shape
# is identical between the two backends, so the emitter walks them the
# same way.
#
# Contract (SPEC §encode):
#   decode(encode(decode(source))) is data-equivalent to decode(source),
#   has the same comments at the same attached paths, and uses the same
#   literal forms for values where preserved (integer base, string form).
#
# Round-trip stability:
#   encode(decode(encode(decode(source)))) is byte-equal to encode(decode(source)).
#
# SPEC v0.14 renamed to_dms/to_dms_lite to encode/encode_lite. The old
# names remain as deprecated aliases for one release.
#
# A Document is a hashref:
#   { meta => undef|tied-hash, body => value, comments => [...],
#     original_forms => [ [path_aref, lit_href], ... ] }

use strict;
use warnings;
use utf8;
use Scalar::Util qw(blessed);
use POSIX qw(isnan isinf);
use Carp ();

our $VERSION = '0.5.3';

my $INDENT_STR = '  ';

# Public entry point. $doc is the decode_document return value.
# SPEC §encode (v0.14): renamed from to_dms() to encode().
sub encode {
    my ($doc) = @_;
    return _emit($doc, 0);
}

# Lite-mode entry point — emits canonical DMS source with no comments
# and no original-form preservation (decimal integers, basic-quoted
# strings). Mirrors the Rust reference's `encode_lite`. SPEC §encode.
#
# `decode(encode_lite(doc))` is data-equivalent to `doc`; it is
# *not* required to round-trip comments or literal forms.
sub encode_lite {
    my ($doc) = @_;
    return _emit($doc, 1);
}

# Deprecated aliases (SPEC v0.14 renamed to_dms/to_dms_lite to
# encode/encode_lite). Kept for one release. Carp once per process to
# avoid flooding callers that loop.
{ my $warned;
  sub to_dms {
      unless ($warned++) {
          Carp::carp(
              'DMS::Parser::Emitter::to_dms() is deprecated; use encode() instead. '
            . 'SPEC v0.14 renamed to_dms() to encode().');
      }
      goto &encode;
  }
}
{ my $warned;
  sub to_dms_lite {
      unless ($warned++) {
          Carp::carp(
              'DMS::Parser::Emitter::to_dms_lite() is deprecated; use encode_lite() instead. '
            . 'SPEC v0.14 renamed to_dms_lite() to encode_lite().');
      }
      goto &encode_lite;
  }
}

sub _emit {
    my ($doc, $lite) = @_;
    # SPEC §"Unordered tables": full-mode `encode` refuses to round-trip
    # a Document that contains a DMS::Parser::UnorderedTable. The Document tree
    # has no stable iteration order, so re-emission cannot be byte-stable.
    # Lite mode is allowed (canonical emit, no order promise).
    if (!$lite && _contains_unordered($doc->{body})) {
        die "encode (full-mode round-trip) refuses Document with DMS::Parser::UnorderedTable; "
          . "use decode_document (ordered) or encode_lite. SPEC §Unordered tables.\n";
    }
    if (!$lite && defined($doc->{meta}) && _contains_unordered($doc->{meta})) {
        die "encode (full-mode round-trip) refuses Document with DMS::Parser::UnorderedTable; "
          . "use decode_document (ordered) or encode_lite. SPEC §Unordered tables.\n";
    }
    my $self = bless {
        out => '',
        comments_by_path => {},   # path-key -> { leading=>[], trailing=>scalar/undef, floating=>[] }
        forms_by_path    => {},   # path-key -> $lit
        lite => $lite ? 1 : 0,
        doc => $doc,
    }, __PACKAGE__;
    # In lite mode, the per-path comment + original-form maps stay
    # empty: the walk then emits canonical form even when `doc.comments`
    # / `doc.original_forms` are populated. Mirrors the Rust emitter's
    # `new_lite` constructor.
    if (!$self->{lite}) {
        # Bucket comments + original_forms by path-key (joined string).
        for my $ac (@{ $doc->{comments} || [] }) {
            my $pk = _path_key($ac->{path});
            $self->{comments_by_path}{$pk} ||= { leading => [], inner => [], trailing => [], floating => [] };
            my $entry = $self->{comments_by_path}{$pk};
            my $pos = $ac->{position};
            if ($pos eq 'leading') {
                push @{ $entry->{leading} }, $ac->{comment};
            } elsif ($pos eq 'inner') {
                push @{ $entry->{inner} }, $ac->{comment};
            } elsif ($pos eq 'trailing') {
                push @{ $entry->{trailing} }, $ac->{comment};
            } else {
                push @{ $entry->{floating} }, $ac->{comment};
            }
        }
        for my $pair (@{ $doc->{original_forms} || [] }) {
            my ($p, $lit) = @$pair;
            my $pk = _path_key($p);
            $self->{forms_by_path}{$pk} = $lit if !exists $self->{forms_by_path}{$pk};
        }
    }

    $self->_emit_document;
    return $self->{out};
}

# --- path-key encoding ---
# A path is an arrayref of plain string segments (table keys) and
# DMS::Parser::Index objects (list indices). We encode each segment with a
# distinct prefix so the join is unambiguous (a string key "0" doesn't
# collide with index 0).
sub _path_key {
    my ($p) = @_;
    return join("\0", map {
        ref($_) eq 'DMS::Parser::Index' ? "I:" . $$_ : "K:$_"
    } @$p);
}

sub _emit_document {
    my $self = shift;
    my $doc = $self->{doc};

    # Front matter: emit the `+++` block when meta is defined OR when
    # any `__fm__`-prefixed comment exists. Spec §to_dms allows omitting
    # an empty-meta block when no FM comments either, but emitting `+++\n+++\n`
    # for an empty-meta doc with no FM comments would be wrong; the
    # has_meta test below guards that.
    # Lite mode emits no comments, so FM comments don't force a `+++`
    # block — only an explicit `meta = Some(...)` does. Mirrors the
    # Rust reference (lib.rs::emit_document `!self.lite && ...`).
    my $has_fm_comments = 0;
    if (!$self->{lite}) {
        for my $ac (@{ $doc->{comments} || [] }) {
            my $first = $ac->{path}[0];
            if (defined($first) && !ref($first) && $first eq '__fm__') {
                $has_fm_comments = 1; last;
            }
        }
    }
    my $fm_present = defined $doc->{meta};
    if ($fm_present || $has_fm_comments) {
        $self->{out} .= "+++\n";
        my $fm_path = ['__fm__'];
        if (defined $doc->{meta}) {
            $self->_emit_table_block($doc->{meta}, $fm_path, 0);
        } else {
            $self->_emit_floating($fm_path, 0);
        }
        $self->{out} .= "+++\n\n";
    }

    my $body_path = [];
    my $body = $doc->{body};
    if (_is_table($body)) {
        $self->_emit_table_block($body, $body_path, 0);
    } elsif (_is_list($body)) {
        $self->_emit_list_block($body, $body_path, 0);
    } else {
        # Scalar root.
        my $nc = $self->{comments_by_path}{ _path_key($body_path) };
        if ($nc) {
            for my $c (@{ $nc->{leading} }) {
                $self->_emit_comment_line($c, 0);
            }
        }
        $self->_emit_value_inline($body, $body_path);
        $self->_emit_trailing_for($body_path);
        $self->{out} .= "\n";
        if ($nc) {
            for my $c (@{ $nc->{floating} }) {
                $self->_emit_comment_line($c, 0);
            }
        }
    }
}

sub _is_table {
    my ($v) = @_;
    return 0 if !defined $v;
    # SPEC §"Unordered tables": DMS::Parser::UnorderedTable is a blessed hashref
    # marker. Treat it as a table for emission purposes; the full-mode
    # to_dms guard above prevents it from reaching here in round-trip.
    if (blessed($v)) {
        return ref($v) eq 'DMS::Parser::UnorderedTable';
    }
    return ref($v) eq 'HASH';
}

sub _is_list {
    my ($v) = @_;
    return 0 if !defined $v;
    return 0 if blessed($v);
    return ref($v) eq 'ARRAY';
}

sub _table_keys {
    my ($t) = @_;
    # Fast path: when the table is a Tie::IxHash, bypass tie magic and
    # read the keys AV directly. The tied object is a blessed arrayref
    # `[idx_hv_rv, keys_av_rv, vals_av_rv, iter]` per Tie::IxHash's
    # documented internal shape. `keys %$t` works too but goes through
    # every entry's mg_find — measurably slower on a 5000-pair tree.
    my $tied = tied(%$t);
    if ($tied && ref($tied) eq 'Tie::IxHash') {
        return @{ $tied->[1] };
    }
    # DMS::Parser::UnorderedTable (plain blessed hash) or plain HV: arbitrary
    # iteration order is the documented contract for lite mode.
    return keys %$t;
}

# Recursive walk: returns true if any nested table (or the value itself)
# is a DMS::Parser::UnorderedTable. Used by `to_dms` (full mode) to refuse
# round-trip on unordered Documents per SPEC §"Unordered tables".
sub _contains_unordered {
    my ($v) = @_;
    return 0 if !defined $v;
    if (blessed($v)) {
        # DMS::Parser::UnorderedTable is itself the marker — we don't need to
        # walk into it because finding the outer one is enough; any
        # nested UnorderedTable would still be detected via the body.
        return 1 if ref($v) eq 'DMS::Parser::UnorderedTable';
        # Other blessed sentinels (DMS::Parser::Integer, DMS::Parser::Bool, dates,
        # DMS::Parser::Float) are leaves.
        return 0;
    }
    if (ref($v) eq 'HASH') {
        for my $k (keys %$v) {
            next if $k eq "\0_keys";
            return 1 if _contains_unordered($v->{$k});
        }
        return 0;
    }
    if (ref($v) eq 'ARRAY') {
        for my $item (@$v) {
            return 1 if _contains_unordered($item);
        }
        return 0;
    }
    return 0;
}

sub _emit_table_block {
    my ($self, $t, $path, $indent) = @_;
    # Lite-mode hot path: no comments, no original_forms, so the per-kvpair
    # path/path-key construction and comment-map lookups are pure overhead.
    # Skipping them saves ~35% of emit wall time on a 5000-kvpair Helm
    # chart values.yaml fixture (the path-building inner-array copy plus
    # _path_key string-join was the dominant cost).
    if ($self->{lite}) {
        my $pad = $INDENT_STR x $indent;
        for my $k (_table_keys($t)) {
            my $v = $t->{$k};
            my $r = ref($v);
            # Inline the common scalar cases. The realistic fixture is
            # >90% plain-string + a few bool/int values; dispatching to
            # _emit_value_inline + _emit_string per kvpair was the
            # dominant cost after the path-key skip.
            if (!$r) {
                my $key_fmt = ($k =~ /\A[A-Za-z_][A-Za-z0-9_-]*\z/)
                    ? $k : _format_key($k);
                if ($v !~ /[\\"\x00-\x1F]/) {
                    $self->{out} .= "${pad}${key_fmt}: \"${v}\"\n";
                } else {
                    $self->{out} .= "${pad}${key_fmt}: \"" . _escape_basic($v) . "\"\n";
                }
                next;
            }
            if ($r eq 'DMS::Parser::Bool') {
                my $key_fmt = ($k =~ /\A[A-Za-z_][A-Za-z0-9_-]*\z/)
                    ? $k : _format_key($k);
                $self->{out} .= $pad . $key_fmt . ': '
                    . ($$v ? "true\n" : "false\n");
                next;
            }
            if ($r eq 'DMS::Parser::Integer') {
                my $key_fmt = ($k =~ /\A[A-Za-z_][A-Za-z0-9_-]*\z/)
                    ? $k : _format_key($k);
                $self->{out} .= "${pad}${key_fmt}: ${$v}\n";
                next;
            }
            my $can_block =
                (_is_table($v) && scalar(_table_keys($v))) ||
                (_is_list($v)  && scalar(@$v));
            $self->{out} .= $pad;
            $self->{out} .= _format_key($k);
            $self->{out} .= ':';
            if ($can_block) {
                $self->{out} .= "\n";
                if (_is_table($v)) {
                    $self->_emit_table_block($v, undef, $indent + 1);
                } else {
                    $self->_emit_list_block($v, undef, $indent + 1);
                }
            } else {
                $self->{out} .= ' ';
                $self->_emit_value_inline($v, undef);
                $self->{out} .= "\n";
            }
        }
        return;
    }
    for my $k (_table_keys($t)) {
        my $v = $t->{$k};
        my $child_path = [ @$path, $k ];
        my $child_pk = _path_key($child_path);
        my $nc = $self->{comments_by_path}{$child_pk};
        if ($nc) {
            for my $c (@{ $nc->{leading} }) {
                $self->_emit_comment_line($c, $indent);
            }
        }
        my $has_trailing = $nc && @{ $nc->{trailing} };
        my $has_inner = $self->_has_inner($child_path);
        my $can_block =
            (_is_table($v) && scalar(_table_keys($v))) ||
            (_is_list($v)  && scalar(@$v));
        my $needs_block = $can_block && !($has_trailing && $self->_is_flow_safe($v, $child_path));
        $self->{out} .= $INDENT_STR x $indent;
        $self->{out} .= _format_key($k);
        $self->{out} .= ':';
        if ($needs_block) {
            if ($has_inner) {
                $self->{out} .= ' ';
                $self->_emit_inner_for($child_path);
                # Trim trailing space left by _emit_inner_for.
                $self->{out} =~ s/ \z//;
            }
            $self->{out} .= "\n";
            if (_is_table($v)) { $self->_emit_table_block($v, $child_path, $indent + 1); }
            else               { $self->_emit_list_block($v,  $child_path, $indent + 1); }
        } else {
            $self->{out} .= ' ';
            $self->_emit_inner_for($child_path);
            $self->_emit_value_inline($v, $child_path);
            $self->_emit_trailing_for($child_path);
            $self->{out} .= "\n";
        }
    }
    $self->_emit_floating($path, $indent);
}

sub _emit_list_block {
    my ($self, $items, $path, $indent) = @_;
    if ($self->{lite}) {
        my $pad = $INDENT_STR x $indent;
        for (my $i = 0; $i < @$items; $i++) {
            my $v = $items->[$i];
            $self->{out} .= $pad;
            $self->{out} .= '+';
            if (_is_table($v) && scalar(_table_keys($v))) {
                $self->{out} .= "\n";
                $self->_emit_table_block($v, undef, $indent + 1);
            } elsif (_is_list($v) && scalar(@$v)) {
                $self->{out} .= "\n";
                $self->_emit_list_block($v, undef, $indent + 1);
            } else {
                $self->{out} .= ' ';
                $self->_emit_value_inline($v, undef);
                $self->{out} .= "\n";
            }
        }
        return;
    }
    for (my $i = 0; $i < @$items; $i++) {
        my $v = $items->[$i];
        my $child_path = [ @$path, DMS::Parser::Index->new($i) ];
        my $child_pk = _path_key($child_path);
        my $nc = $self->{comments_by_path}{$child_pk};
        if ($nc) {
            for my $c (@{ $nc->{leading} }) {
                $self->_emit_comment_line($c, $indent);
            }
        }
        $self->{out} .= $INDENT_STR x $indent;
        $self->{out} .= '+';
        my $has_inner = $self->_has_inner($child_path);
        if (_is_table($v) && scalar(_table_keys($v))) {
            if ($has_inner) {
                $self->{out} .= ' ';
                $self->_emit_inner_for($child_path);
                $self->{out} =~ s/ \z//;
            }
            $self->_emit_trailing_for($child_path);
            $self->{out} .= "\n";
            $self->_emit_table_block($v, $child_path, $indent + 1);
        } elsif (_is_list($v) && scalar(@$v)) {
            if ($has_inner) {
                $self->{out} .= ' ';
                $self->_emit_inner_for($child_path);
                $self->{out} =~ s/ \z//;
            }
            $self->_emit_trailing_for($child_path);
            $self->{out} .= "\n";
            $self->_emit_list_block($v, $child_path, $indent + 1);
        } else {
            $self->{out} .= ' ';
            $self->_emit_inner_for($child_path);
            $self->_emit_value_inline($v, $child_path);
            $self->_emit_trailing_for($child_path);
            $self->{out} .= "\n";
        }
    }
    $self->_emit_floating($path, $indent);
}

sub _emit_value_inline {
    my ($self, $v, $path) = @_;
    if (blessed($v)) {
        my $cls = ref($v);
        if    ($cls eq 'DMS::Parser::Bool')          { $self->{out} .= $v->value ? 'true' : 'false'; }
        elsif ($cls eq 'DMS::Parser::Integer')       { $self->_emit_integer($v, $path); }
        elsif ($cls eq 'DMS::Parser::Float')         { $self->_emit_float($v->value); }
        elsif ($cls eq 'DMS::Parser::OffsetDateTime'
            || $cls eq 'DMS::Parser::LocalDateTime'
            || $cls eq 'DMS::Parser::LocalDate'
            || $cls eq 'DMS::Parser::LocalTime')     { $self->{out} .= $v->value; }
        else { die "to_dms: unknown blessed class $cls"; }
        return;
    }
    if (_is_list($v)) {
        if (!@$v) { $self->{out} .= '[]'; return; }
        $self->{out} .= '[';
        my $lite = $self->{lite};
        for (my $i = 0; $i < @$v; $i++) {
            $self->{out} .= ', ' if $i > 0;
            my $sub = $lite ? undef : [ @$path, DMS::Parser::Index->new($i) ];
            $self->_emit_value_inline($v->[$i], $sub);
        }
        $self->{out} .= ']';
        return;
    }
    if (_is_table($v)) {
        my @keys = _table_keys($v);
        if (!@keys) { $self->{out} .= '{}'; return; }
        $self->{out} .= '{';
        my $first = 1;
        my $lite = $self->{lite};
        for my $k (@keys) {
            $self->{out} .= ', ' unless $first;
            $first = 0;
            $self->{out} .= _format_key($k);
            $self->{out} .= ': ';
            my $sub = $lite ? undef : [ @$path, $k ];
            $self->_emit_value_inline($v->{$k}, $sub);
        }
        $self->{out} .= '}';
        return;
    }
    # Plain scalar = string.
    if (!defined $v) { die "to_dms: got undef value"; }
    $self->_emit_string("$v", $path);
}

sub _emit_integer {
    my ($self, $iv, $path) = @_;
    if ($self->{lite}) {
        # DMS::Parser::Integer is `bless \$v, 'DMS::Parser::Integer'` where $v is an IV.
        # Direct deref + string concat skips the bstr() method dispatch.
        $self->{out} .= "${$iv}";
        return;
    }
    my $lit_ref = $self->{forms_by_path}{ _path_key($path) };
    if ($lit_ref && exists $lit_ref->{integer_lit}) {
        $self->{out} .= $lit_ref->{integer_lit};
        return;
    }
    # Default: canonical decimal. DMS::Parser::Integer's bstr stringifies the IV.
    $self->{out} .= $iv->bstr;
}

sub _emit_float {
    my ($self, $f) = @_;
    if (isnan($f))    { $self->{out} .= 'nan'; return; }
    if (isinf($f))    { $self->{out} .= ($f > 0 ? 'inf' : '-inf'); return; }
    # ryu-shortest equivalent: try increasing %.Ng until round-trip works.
    for my $p (1..17) {
        my $s = sprintf("%.${p}g", $f);
        if (0 + $s == $f) {
            $s =~ s/e\+/e/;
            $s =~ s/e-0+(\d)/e-$1/;
            $s =~ s/e0+(\d)/e$1/;
            if ($s !~ /[.eE]/) { $s .= '.0'; }
            $self->{out} .= $s;
            return;
        }
    }
    $self->{out} .= sprintf("%.17g", $f);
}

sub _emit_string {
    my ($self, $s, $path) = @_;
    if ($self->{lite}) {
        $self->{out} .= '"';
        $self->{out} .= _escape_basic($s);
        $self->{out} .= '"';
        return;
    }
    my $lit_ref = $self->{forms_by_path}{ _path_key($path) };
    my $form;
    if ($lit_ref && exists $lit_ref->{string_form}) {
        $form = $lit_ref->{string_form};
    }
    if (!$form || $form->{kind} eq 'basic') {
        $self->{out} .= '"';
        $self->{out} .= _escape_basic($s);
        $self->{out} .= '"';
        return;
    }
    if ($form->{kind} eq 'literal') {
        $self->{out} .= "'";
        $self->{out} .= $s;
        $self->{out} .= "'";
        return;
    }
    if ($form->{kind} eq 'heredoc') {
        # The stored body is post-modifier. For idempotent modifiers this
        # is fine, but `_fold_paragraphs` joins lines within a paragraph
        # with spaces — so we pre-expand each `\n` to `\n\n` so the
        # re-applied modifier preserves line boundaries on round-trip.
        my $body = $s;
        my $has_fold = 0;
        for my $m (@{ $form->{modifiers} || [] }) {
            if ($m->{name} eq '_fold_paragraphs') { $has_fold = 1; last; }
        }
        if ($has_fold) {
            $body =~ s/\n/\n\n/g;
        }
        $self->_emit_heredoc($body, $form->{flavor}, $form->{label}, $form->{modifiers} || []);
        return;
    }
    die "to_dms: unknown string form: $form->{kind}";
}

sub _emit_heredoc {
    my ($self, $body, $flavor, $label, $modifiers) = @_;
    # Compute the kvpair's indent from the most recent newline in $self->{out}.
    my $bytes = $self->{out};
    my $last_nl = rindex($bytes, "\n");
    my $line_start = $last_nl < 0 ? 0 : $last_nl + 1;
    my $kv_indent_spaces = 0;
    while ($line_start + $kv_indent_spaces < length($bytes)
           && substr($bytes, $line_start + $kv_indent_spaces, 1) eq ' ') {
        $kv_indent_spaces++;
    }
    my $body_indent_str = ' ' x ($kv_indent_spaces + length($INDENT_STR));
    my $term_indent_str = $body_indent_str;
    my $opener = ($flavor eq 'basic_triple') ? '"""' : "'''";
    $self->{out} .= $opener;
    $self->{out} .= $label if defined $label;
    for my $m (@$modifiers) {
        $self->{out} .= ' ';
        $self->{out} .= $m->{name};
        $self->{out} .= '(';
        my $first = 1;
        for my $a (@{ $m->{args} || [] }) {
            $self->{out} .= ', ' unless $first;
            $first = 0;
            $self->_emit_modifier_arg($a);
        }
        $self->{out} .= ')';
    }
    $self->{out} .= "\n";
    if (length($body) == 0) {
        # nothing — terminator on its own line follows
    } else {
        for my $line (split /\n/, $body, -1) {
            if (length($line) == 0) {
                $self->{out} .= "\n";
            } else {
                $self->{out} .= $body_indent_str;
                $self->{out} .= $line;
                $self->{out} .= "\n";
            }
        }
    }
    $self->{out} .= $term_indent_str;
    if (defined $label) {
        $self->{out} .= $label;
    } else {
        $self->{out} .= ($flavor eq 'basic_triple') ? '"""' : "'''";
    }
}

sub _emit_modifier_arg {
    my ($self, $v) = @_;
    if (blessed($v)) {
        my $cls = ref($v);
        if    ($cls eq 'DMS::Parser::Bool')    { $self->{out} .= $v->value ? 'true' : 'false'; }
        elsif ($cls eq 'DMS::Parser::Integer') { $self->{out} .= $v->bstr; }
        elsif ($cls eq 'DMS::Parser::Float')   { $self->_emit_float($v->value); }
        elsif ($cls eq 'DMS::Parser::OffsetDateTime'
            || $cls eq 'DMS::Parser::LocalDateTime'
            || $cls eq 'DMS::Parser::LocalDate'
            || $cls eq 'DMS::Parser::LocalTime') { $self->{out} .= $v->value; }
        else { die "modifier arg: unknown blessed class $cls"; }
        return;
    }
    if (_is_list($v)) { $self->{out} .= '[]'; return; }
    if (_is_table($v)) { $self->{out} .= '{}'; return; }
    # Plain scalar = string. Modifier args use basic-quoted always.
    $self->{out} .= '"';
    $self->{out} .= _escape_basic("$v");
    $self->{out} .= '"';
}

sub _emit_comment_line {
    my ($self, $c, $indent) = @_;
    my $text = $c->{content};
    my $prefix = $INDENT_STR x $indent;
    if (index($text, "\n") < 0) {
        $self->{out} .= $prefix;
        $self->{out} .= $text;
        $self->{out} .= "\n";
        return;
    }
    # Multi-line: only the first line gets re-indented; subsequent body
    # lines keep their original whitespace verbatim.
    my @lines = split /\n/, $text, -1;
    for (my $i = 0; $i < @lines; $i++) {
        if ($i == 0) {
            $self->{out} .= $prefix;
            $self->{out} .= $lines[$i];
        } else {
            $self->{out} .= "\n";
            $self->{out} .= $lines[$i];
        }
    }
    $self->{out} .= "\n";
}

sub _emit_trailing_for {
    my ($self, $path) = @_;
    return if $self->{lite};
    my $nc = $self->{comments_by_path}{ _path_key($path) };
    return if !$nc || !@{ $nc->{trailing} };
    my $first = 1;
    for my $c (@{ $nc->{trailing} }) {
        $self->{out} .= ($first ? '  ' : ' ');
        $first = 0;
        $self->{out} .= $c->{content};
    }
}

sub _emit_inner_for {
    my ($self, $path) = @_;
    return if $self->{lite};
    my $nc = $self->{comments_by_path}{ _path_key($path) };
    return if !$nc;
    for my $c (@{ $nc->{inner} }) {
        $self->{out} .= $c->{content};
        $self->{out} .= ' ';
    }
}

sub _has_inner {
    my ($self, $path) = @_;
    return 0 if $self->{lite};
    my $nc = $self->{comments_by_path}{ _path_key($path) };
    return $nc && @{ $nc->{inner} };
}

sub _emit_floating {
    my ($self, $path, $indent) = @_;
    return if $self->{lite};
    my $nc = $self->{comments_by_path}{ _path_key($path) };
    return if !$nc;
    for my $c (@{ $nc->{floating} }) {
        $self->_emit_comment_line($c, $indent);
    }
}

# Returns true if $v rooted at $path is safe to emit as a flow form: no
# heredoc strings (heredocs need their own line) and no descendant has
# an attached comment (flow has nowhere to put it). Used to decide
# flow-vs-block when a trailing comment forces flow form.
sub _is_flow_safe {
    my ($self, $v, $path) = @_;
    my $pk_prefix = _path_key($path);
    # Any descendant comment ⇒ unsafe. Skipped in lite mode (no
    # comments are emitted anyway). Mirrors Rust lib.rs::is_flow_safe.
    if (!$self->{lite}) {
        for my $ac (@{ $self->{doc}{comments} || [] }) {
            next if scalar(@{ $ac->{path} }) <= scalar(@$path);
            my $apk = _path_key($ac->{path});
            my $prefix = $pk_prefix eq '' ? '' : "$pk_prefix\0";
            if ($pk_prefix eq '') {
                # any non-empty path is descendant of root
                return 0;
            } elsif (substr($apk, 0, length($prefix)) eq $prefix) {
                return 0;
            }
        }
    }
    if (!ref($v) && !blessed($v)) {
        # plain string: check heredoc form
        my $lit = $self->{forms_by_path}{ _path_key($path) };
        if ($lit && exists $lit->{string_form} && $lit->{string_form}{kind} eq 'heredoc') {
            return 0;
        }
        return 1;
    }
    if (blessed($v)) { return 1; }
    if (_is_list($v)) {
        for (my $i = 0; $i < @$v; $i++) {
            my $sub = [ @$path, DMS::Parser::Index->new($i) ];
            return 0 if !$self->_is_flow_safe($v->[$i], $sub);
        }
        return 1;
    }
    if (_is_table($v)) {
        for my $k (_table_keys($v)) {
            my $sub = [ @$path, $k ];
            return 0 if !$self->_is_flow_safe($v->{$k}, $sub);
        }
        return 1;
    }
    return 1;
}

sub _escape_basic {
    my ($s) = @_;
    # Fast path: most strings need no escaping. Skip the per-char split
    # if the string contains no `\`, no `"`, and no control chars.
    return $s if $s !~ /[\\"\x00-\x1F]/;
    my $out = '';
    for my $ch (split //, $s) {
        my $code = ord($ch);
        if    ($ch eq '\\') { $out .= '\\\\'; }
        elsif ($ch eq '"')  { $out .= '\\"'; }
        elsif ($ch eq "\n") { $out .= '\\n'; }
        elsif ($ch eq "\r") { $out .= '\\r'; }
        elsif ($ch eq "\t") { $out .= '\\t'; }
        elsif ($ch eq "\b") { $out .= '\\b'; }
        elsif ($ch eq "\f") { $out .= '\\f'; }
        elsif ($code < 0x20) { $out .= sprintf('\\u%04X', $code); }
        else { $out .= $ch; }
    }
    return $out;
}

sub _is_bare_key_char_emit {
    my ($c) = @_;
    return 1 if $c eq '_' || $c eq '-';
    my $o = ord($c);
    if ($o < 128) {
        return $c =~ /[A-Za-z0-9]/;
    }
    # Match the parser's frozen Unicode 15.1 XID_Continue snapshot so that
    # to_dms emits a key bare iff the parser would accept it bare. Avoids
    # producing surface forms that drift with the host's Unicode tables.
    require DMS::Parser;
    return DMS::Parser::_is_xid_continue($o);
}

sub _format_key {
    my ($k) = @_;
    # ASCII fast path. Real-world keys are >99% plain ASCII identifiers;
    # the regex bails out at the first non-bare char without splitting
    # the string into single-char SVs. Saves per-key allocations.
    return $k if $k =~ /\A[A-Za-z_][A-Za-z0-9_-]*\z/;
    if (length($k) > 0) {
        my $bare = 1;
        for my $ch (split //, $k) {
            if (!_is_bare_key_char_emit($ch)) { $bare = 0; last; }
        }
        return $k if $bare;
    }
    # Quoted: prefer literal if no single quote, no LF/CR.
    if (index($k, "'") < 0 && index($k, "\n") < 0 && index($k, "\r") < 0) {
        return "'$k'";
    }
    return '"' . _escape_basic($k) . '"';
}

1;

__END__

=encoding UTF-8

=head1 NAME

DMS::Parser::Emitter - Re-emit a parsed DMS Document as DMS source

=head1 SYNOPSIS

  use DMS::Parser;
  use DMS::Parser::Emitter;

  my $doc = DMS::Parser::decode_document($src);

  # Full round-trip: preserves comments and original literal forms
  my $dms = DMS::Parser::Emitter::encode($doc);

  # Lite mode: canonical DMS, no comments, decimal integers, basic-quoted strings
  my $canonical = DMS::Parser::Emitter::encode_lite($doc);

=head1 DESCRIPTION

DMS::Parser::Emitter converts a parsed DMS Document hashref back into DMS source
text. It is the shared emitter used by both L<DMS::Parser> (pure-Perl backend)
and L<DMS::Parser::XS> (XS backend) — the Document shape is identical between
the two, so the same walker handles both.

=head2 Round-trip contract (SPEC §encode)

Full mode (C<encode>):

=over 4

=item * C<decode(encode(decode(source)))> is I<data-equivalent> to C<decode(source)>.

=item * Comments are re-emitted at the same attached paths.

=item * Original literal forms are preserved where recorded in C<< $doc->{original_forms} >>:
integer bases (hex, octal, binary), string forms (literal-quoted, heredocs with
modifiers).

=item * C<encode> refuses a Document whose body contains a L<DMS::Parser::UnorderedTable>;
use C<encode_lite> instead (no order guarantee).

=back

Lite mode (C<encode_lite>):

=over 4

=item * Emits canonical DMS: no comments, decimal integers, basic-quoted strings.

=item * C<decode(encode_lite($doc))> is data-equivalent to C<$doc>; comment and
literal-form round-trip is I<not> guaranteed.

=item * Accepts L<DMS::Parser::UnorderedTable> (arbitrary key order).

=back

=head1 FUNCTIONS

=head2 encode($doc)

Re-emit the Document C<$doc> (as returned by C<decode_document>) as a DMS source
string. Preserves comments attached to the tree and original literal forms
recorded in C<< $doc->{original_forms} >>. Dies if the body contains a
L<DMS::Parser::UnorderedTable>.

=head2 encode_lite($doc)

Emit canonical DMS source: no comments, no literal-form preservation. Safe to
call on any Document including those with L<DMS::Parser::UnorderedTable>.

=head2 to_dms($doc)

Deprecated alias for L</encode>. Emits a one-time C<Carp::carp> warning and
forwards. Will be removed in the next release.

=head2 to_dms_lite($doc)

Deprecated alias for L</encode_lite>. Emits a one-time C<Carp::carp> warning and
forwards. Will be removed in the next release.

=head1 SEE ALSO

L<DMS::Parser>, L<DMS::Parser::XS>, L<https://gitlab.com/flo-labs/pub/dms>

=head1 AUTHOR

Filip Lopes

=head1 LICENSE

Dual-licensed under the Apache License 2.0 and the MIT license, at your option.

=cut
