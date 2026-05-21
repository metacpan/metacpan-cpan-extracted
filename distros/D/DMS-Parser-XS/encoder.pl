#!/usr/bin/env perl
# XS-backed DMS conformance encoder. Mirrors language/perl/encoder.pl
# byte-for-byte; the only difference is the parser module.
# With --roundtrip, instead emit DMS source via encode (round-trip mode).
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/blib/lib";
use lib "$FindBin::Bin/blib/arch";
use lib "$FindBin::Bin/../DMS/lib";
use DMS::Parser::XS;
use DMS::Parser::Tier1;
use Tie::IxHash;
my @PAD;
sub _pad { return $PAD[$_[0]] //= ('  ' x $_[0]); }
use Scalar::Util qw(blessed looks_like_number);
use POSIX qw(isnan isinf);
use Time::HiRes ();

binmode(STDIN);
binmode(STDERR, ':utf8');

# CLI flag parsing — see encoder.pl (pure-Perl) for protocol notes.
# Mirrors Rust / Go reference encoders. SPEC: dms-tests/TESTS.md §3a.
my $roundtrip    = 0;
my $bench_iters  = 0;
my $bench_warmup = 3;
my $mode         = defined $ENV{DMS_MODE} && $ENV{DMS_MODE} ne ''
                 ? $ENV{DMS_MODE} : 'full';
my $ignore_order = exists $ENV{DMS_IGNORE_ORDER} ? 1 : 0;
my $tier         = 0;
my $argi = 0;
while ($argi < @ARGV) {
    my $arg = $ARGV[$argi];
    if ($arg eq '--roundtrip') { $roundtrip = 1; }
    elsif ($arg eq '--ignore-order') { $ignore_order = 1; }
    elsif ($arg eq '--tier=0') { $tier = 0; }
    elsif ($arg eq '--tier=1') { $tier = 1; }
    elsif ($arg =~ /^--tier=(\d+)$/) { $tier = int($1); }
    elsif ($arg eq '--bench-iters') {
        $bench_iters = $ARGV[++$argi] // 0;
    }
    elsif ($arg eq '--bench-warmup') {
        $bench_warmup = $ARGV[++$argi] // 3;
    }
    elsif ($arg eq '--mode') {
        $mode = $ARGV[++$argi] // 'full';
    }
    else { print STDERR "unknown arg: $arg\n"; exit 2; }
    $argi++;
}
$bench_iters  += 0;
$bench_warmup += 0;
if ($mode ne 'full' && $mode ne 'lite') {
    print STDERR "0:0: --mode must be full|lite, got \"$mode\"\n";
    exit 1;
}
my $lite = ($mode eq 'lite');

# Fast path: parse + JSON-emit happens entirely in C, including stdin
# slurp and stdout write. Skips two SV<->C buffer copies (input slurp
# into an SV, output SV that Perl `print`s) plus the SV/HV/AV/Tie::IxHash
# construction that decode_document does. For wide flat documents
# (flat50k bench) that round trip is the dominant cost. Set STDOUT to
# pure :raw — encode_stdin_to_stdout writes pre-validated UTF-8 bytes
# directly via PerlIO and we don't want the :utf8 layer to re-check or
# transcode them. The roundtrip path still needs the full Perl tree
# (comments, original_forms, etc.) so it falls through to decode_document
# below; that path keeps the :utf8 layer.
#
# encode_stdin_to_stdout internally calls dms_parse_document_lite — it's
# the lite-mode fast path. We take it only under DMS_MODE=lite so that
# DMS_MODE=full actually exercises the full parser (Tie::IxHash tables
# + comment AST + original_forms construction) on the conformance
# corpus. SPEC §"Parsing modes — full and lite".
#
# We bypass the C fast path when we need the parsed Document in Perl:
# - bench mode loops emit (needs $doc),
# - roundtrip needs specific emitters that operate on the Perl tree,
# - DMS_MODE=full needs the full parser path,
# - --ignore-order needs DMS::Parser::UnorderedTable wrapping in Perl.
# The C fast path handles empty stdin by emitting "{}" and exiting 0,
# which still satisfies the "empty stdin → exit 0" probe contract.
if ($tier == 1 && !$roundtrip && $bench_iters == 0) {
    binmode(STDOUT, ':raw:utf8');
    binmode(STDIN,  ':raw:utf8');
    my $src = do { local $/; <STDIN> };
    if (!defined $src || $src =~ /\A\s*\z/) { exit 0; }
    # Fast path: decode_t1_to_json returns the conformance-format JSON directly
    # from the C FFI. Print it and exit — no Perl-side re-encoding needed.
    if (DMS::Parser::XS->can('decode_t1_to_json')) {
        my $json;
        eval { $json = DMS::Parser::XS::decode_t1_to_json($src); };
        if ($@) {
            my $err = $@; chomp $err;
            print STDERR "$err\n";
            exit 1;
        }
        # Normalize trailing newline (C side adds one).
        $json =~ s/\n+\z//;
        print "$json\n";
        exit 0;
    }
    # Fallback: use decode_t1 + Perl re-emitter (pure-Perl tier1 path).
    my $t1_doc;
    eval { $t1_doc = DMS::Parser::XS::decode_t1($src); };
    if ($@) {
        my $err = $@; chomp $err;
        print STDERR "$err\n";
        exit 1;
    }
    print encode_tier1_json($t1_doc) . "\n";
    exit 0;
}

if (!$roundtrip && $bench_iters == 0 && !$ignore_order && $lite) {
    binmode(STDOUT, ':raw');
    eval { DMS::Parser::XS::encode_stdin_to_stdout(); };
    if ($@) {
        my $err = $@;
        chomp $err;
        print STDERR "$err\n";
        exit 1;
    }
    exit 0;
}

binmode(STDOUT, ':raw:utf8');  # ':raw' disables Windows CRLF translation

my $src = do { local $/; <STDIN> };

# Empty stdin → exit 0 (startup probe; matches Go/Rust ref encoders).
# Reachable here only in bench / roundtrip paths; default path handled
# by the C fast path above.
if (!defined $src || $src =~ /\A\s*\z/) {
    exit 0;
}

my $doc;
# SPEC §"Unordered tables": dispatch to the *_unordered entry point
# when --ignore-order is set. The XS C parser doesn't have a native
# unordered backing — the shim parses ordered, then walks the tree
# replacing every table with a DMS::Parser::UnorderedTable plain hashref. Front
# matter remains ordered (per spec).
#
# SPEC §"Parsing modes — full and lite": `--mode lite` (or DMS_MODE=lite)
# routes through decode_document_lite even on the tagged-JSON path. Tagged
# JSON is mode-invariant (same value tree); the dispatch lets conformance
# exercise both parsers under one driver.
eval {
    if ($lite && $ignore_order) {
        $doc = DMS::Parser::XS::decode_lite_document_unordered($src);
    }
    elsif ($lite) {
        $doc = DMS::Parser::XS::decode_document_lite($src);
    }
    elsif ($ignore_order) {
        $doc = DMS::Parser::XS::decode_document_unordered($src);
    }
    else {
        $doc = DMS::Parser::XS::decode_document($src);
    }
};
if ($@) {
    my $err = $@;
    chomp $err;
    print STDERR "$err\n";
    exit 1;
}

# Bench mode: parse once (above, untimed), loop the emit step. Default
# mode emits tagged JSON; --roundtrip emits via encode / encode_lite.
# See dms-tests/TESTS.md §3a.
if ($bench_iters > 0) {
    run_bench($doc, $roundtrip, $lite, $bench_iters, $bench_warmup);
    exit 0;
}

if ($roundtrip) {
    my $out;
    eval {
        $out = $lite
            ? DMS::Parser::XS::encode_lite($doc)
            : DMS::Parser::XS::encode($doc);
        1;
    } or do {
        my $err = $@;
        chomp $err;
        print STDERR "$err\n";
        exit 1;
    };
    print $out;
    exit 0;
}

# Default mode under bench-iters=0 doesn't reach here (handled by the C
# fast path above), but the bench loop's per-iter emit reuses the same
# tagged-JSON helpers below.
my $out;
if (!defined $doc->{meta}) {
    $out = encode_json_value($doc->{body}, 0);
} else {
    $out = encode_document_wrap($doc->{meta}, $doc->{body}, 0);
}
print "$out\n";
exit 0;

# One emit step for the bench loop. Discards the result — caller only
# cares about wall-time. Default-mode timing measures the Perl-level
# tagged-JSON path (not the C fast path); that's intentional: comparing
# the C fast path against languages that do all work in their host VM
# would be apples-to-oranges.
sub _bench_emit {
    my ($doc, $roundtrip, $lite) = @_;
    if ($roundtrip) {
        return $lite
            ? DMS::Parser::XS::encode_lite($doc)
            : DMS::Parser::XS::encode($doc);
    }
    if (!defined $doc->{meta}) {
        return encode_json_value($doc->{body}, 0);
    }
    return encode_document_wrap($doc->{meta}, $doc->{body}, 0);
}

sub run_bench {
    my ($doc, $roundtrip, $lite, $iters, $warmup) = @_;
    for (my $w = 0; $w < $warmup; $w++) {
        my $s = _bench_emit($doc, $roundtrip, $lite);
        my $_unused_w = length($s);
    }
    for (my $j = 0; $j < $iters; $j++) {
        my $t0 = Time::HiRes::clock_gettime(Time::HiRes::CLOCK_MONOTONIC());
        my $s  = _bench_emit($doc, $roundtrip, $lite);
        my $t1 = Time::HiRes::clock_gettime(Time::HiRes::CLOCK_MONOTONIC());
        my $_unused = length($s);
        my $ns = int(($t1 - $t0) * 1e9);
        print "iter $j $ns\n";
    }
}

sub encode_document_wrap {
    my ($meta, $body, $indent) = @_;
    my $pad = '  ' x $indent;
    my $inner = '  ' x ($indent + 1);
    my @parts;
    push @parts, $inner . quote_json('_meta') . ': '
        . encode_json_value($meta, $indent + 1);
    push @parts, $inner . quote_json('_body') . ': '
        . encode_json_value($body, $indent + 1);
    return "{\n" . join(",\n", @parts) . "\n$pad}";
}

sub shortest_float {
    my ($v) = @_;
    if (isnan($v)) { return 'nan'; }
    if (isinf($v)) { return $v > 0 ? 'inf' : '-inf'; }
    for my $p (1..17) {
        my $s = sprintf("%.${p}g", $v);
        if (0 + $s == $v) {
            $s =~ s/e\+/e/;
            $s =~ s/e-0+(\d)/e-$1/;
            $s =~ s/e0+(\d)/e$1/;
            if ($s !~ /[.eE]/) { $s .= '.0'; }
            return $s;
        }
    }
    return sprintf("%.17g", $v);
}

sub quote_json {
    my ($s) = @_;
    my $out = '"';
    for my $ch (split //, $s) {
        my $code = ord($ch);
        if    ($ch eq '"')  { $out .= '\\"'; }
        elsif ($ch eq '\\') { $out .= '\\\\'; }
        elsif ($ch eq "\n") { $out .= '\\n'; }
        elsif ($ch eq "\r") { $out .= '\\r'; }
        elsif ($ch eq "\t") { $out .= '\\t'; }
        elsif ($ch eq "\b") { $out .= '\\b'; }
        elsif ($ch eq "\f") { $out .= '\\f'; }
        elsif ($code < 0x20) { $out .= sprintf('\\u%04x', $code); }
        else { $out .= $ch; }
    }
    return $out . '"';
}

sub encode_json_value {
    my ($v, $indent) = @_;
    my $pad = '  ' x $indent;
    my $inner = '  ' x ($indent + 1);
    if (blessed($v)) {
        my $cls = ref($v);
        # SPEC §"Unordered tables": blessed plain hashref. Emit as a JSON
        # object using whatever order Perl's hash returns (no stability).
        if ($cls eq 'DMS::Parser::UnorderedTable') {
            my @keys = keys %$v;
            return '{}' if !@keys;
            my @parts;
            for (my $i = 0; $i < @keys; $i++) {
                my $k = $keys[$i];
                my $val = encode_json_value($v->{$k}, $indent + 1);
                my $line = $inner . quote_json($k) . ': ' . $val;
                $line .= ',' if $i < $#keys;
                push @parts, $line;
            }
            return "{\n" . join("\n", @parts) . "\n$pad}";
        }
        if ($cls eq 'DMS::Parser::Bool') {
            my $bv = $v->value ? 'true' : 'false';
            return tagged_json('bool', $bv, $indent);
        }
        if ($cls eq 'DMS::Parser::Integer') {
            return tagged_json('integer', $v->value->bstr, $indent);
        }
        if ($cls eq 'DMS::Parser::Float') {
            return tagged_json('float', shortest_float($v->value), $indent);
        }
        if ($cls eq 'DMS::Parser::OffsetDateTime') {
            return tagged_json('offset-datetime', $v->value, $indent);
        }
        if ($cls eq 'DMS::Parser::LocalDateTime') {
            return tagged_json('local-datetime', $v->value, $indent);
        }
        if ($cls eq 'DMS::Parser::LocalDate') {
            return tagged_json('local-date', $v->value, $indent);
        }
        if ($cls eq 'DMS::Parser::LocalTime') {
            return tagged_json('local-time', $v->value, $indent);
        }
        die "unknown blessed value class $cls";
    }
    if (ref($v) eq 'HASH') {
        # XS lite-mode tables have a "\0__dms_keys" insertion-order sidecar;
        # pure-Perl lite-mode tables use "\0_keys". Use whichever is present
        # as the key ordering list, and exclude both sentinels from output.
        my $order = $v->{"\0__dms_keys"} // $v->{"\0_keys"};
        my @keys = $order ? @$order : grep { $_ ne "\0__dms_keys" && $_ ne "\0_keys" } keys %$v;
        return '{}' if !@keys;
        my @parts;
        for (my $i = 0; $i < @keys; $i++) {
            my $k = $keys[$i];
            my $val = encode_json_value($v->{$k}, $indent + 1);
            my $line = $inner . quote_json($k) . ': ' . $val;
            $line .= ',' if $i < $#keys;
            push @parts, $line;
        }
        return "{\n" . join("\n", @parts) . "\n$pad}";
    }
    if (ref($v) eq 'ARRAY') {
        return '[]' if !@$v;
        my @parts;
        for (my $i = 0; $i < @$v; $i++) {
            my $val = encode_json_value($v->[$i], $indent + 1);
            my $line = $inner . $val;
            $line .= ',' if $i < $#$v;
            push @parts, $line;
        }
        return "[\n" . join("\n", @parts) . "\n$pad]";
    }
    if (!defined($v)) { die "got undef value"; }
    return tagged_json('string', "$v", $indent);
}

sub tagged_json {
    my ($t, $v, $indent) = @_;
    my $inner = _pad($indent + 1);
    my $pad   = _pad($indent);
    return "{\n${inner}\"type\": " . quote_json($t) . ",\n${inner}\"value\": " . quote_json($v) . "\n${pad}}";
}

# ── Tier-1 JSON emission ──────────────────────────────────────────────────────

sub encode_tier1_json {
    my ($t1_doc) = @_;
    my $tier       = $t1_doc->{tier};
    my $imports    = $t1_doc->{imports};
    my $body       = $t1_doc->{body};
    my $decorators = $t1_doc->{decorators};

    my @parts;
    push @parts, "  \"tier\": $tier";
    push @parts, "  \"imports\": " . encode_imports_json($imports, 1);
    push @parts, "  \"body\": " . encode_json_value($body, 1);
    push @parts, "  \"decorators\": " . encode_decorators_json($decorators, 1);

    return "{\n" . join(",\n", @parts) . "\n}";
}

sub encode_imports_json {
    my ($imports, $indent) = @_;
    return '[]' unless @$imports;
    my $pad   = _pad($indent);
    my $inner = _pad($indent + 1);
    my @items;
    for my $imp (@$imports) {
        push @items, encode_one_import($imp, $indent + 1);
    }
    return "[\n" . join(",\n", map { "$inner$_" } @items) . "\n$pad]";
}

sub encode_one_import {
    my ($imp, $indent) = @_;
    my $pad   = _pad($indent);
    my $inner = _pad($indent + 1);
    my @parts;

    push @parts, "${inner}\"dialect\": " . quote_json($imp->{dialect});
    push @parts, "${inner}\"version\": " . quote_json($imp->{version});
    push @parts, "${inner}\"ns\": " . (defined $imp->{ns} ? quote_json($imp->{ns}) : 'null');

    # bind
    my $bind = $imp->{bind};
    my @bind_keys = sort keys %$bind;
    if (!@bind_keys) {
        push @parts, "${inner}\"bind\": {}";
    } else {
        my $bi = _pad($indent + 2);
        my @bparts;
        for my $sig (@bind_keys) {
            my @fams = map { quote_json($_) } @{$bind->{$sig}};
            push @bparts, "$bi" . quote_json($sig) . ': [' . join(', ', @fams) . ']';
        }
        push @parts, "${inner}\"bind\": {\n" . join(",\n", @bparts) . "\n${inner}}";
    }

    # allow
    my $allow = $imp->{allow};
    my @allow_keys = sort keys %$allow;
    if (!@allow_keys) {
        push @parts, "${inner}\"allow\": {}";
    } else {
        my $ai = _pad($indent + 2);
        my @aparts;
        for my $fam (@allow_keys) {
            my @ns = map { quote_json($_) } @{$allow->{$fam}};
            push @aparts, "$ai" . quote_json($fam) . ': [' . join(', ', @ns) . ']';
        }
        push @parts, "${inner}\"allow\": {\n" . join(",\n", @aparts) . "\n${inner}}";
    }

    # deny
    my $deny = $imp->{deny};
    my @deny_keys = sort keys %$deny;
    if (!@deny_keys) {
        push @parts, "${inner}\"deny\": {}";
    } else {
        my $di = _pad($indent + 2);
        my @dparts;
        for my $fam (@deny_keys) {
            my @ns = map { quote_json($_) } @{$deny->{$fam}};
            push @dparts, "$di" . quote_json($fam) . ': [' . join(', ', @ns) . ']';
        }
        push @parts, "${inner}\"deny\": {\n" . join(",\n", @dparts) . "\n${inner}}";
    }

    # alias
    my $alias = $imp->{alias};
    my @alias_keys = sort keys %$alias;
    if (!@alias_keys) {
        push @parts, "${inner}\"alias\": {}";
    } else {
        my $ali = _pad($indent + 2);
        my $alii = _pad($indent + 3);
        my @alparts;
        for my $fam (@alias_keys) {
            my $inner_map = $alias->{$fam};
            my @inner_parts;
            for my $ak (sort keys %$inner_map) {
                push @inner_parts, "$alii" . quote_json($ak) . ': ' . quote_json($inner_map->{$ak});
            }
            push @alparts, "$ali" . quote_json($fam) . ": {\n" . join(",\n", @inner_parts) . "\n$ali}";
        }
        push @parts, "${inner}\"alias\": {\n" . join(",\n", @alparts) . "\n${inner}}";
    }

    return "{\n" . join(",\n", @parts) . "\n${pad}}";
}

sub encode_decorators_json {
    my ($decorators, $indent) = @_;
    return '[]' unless @$decorators;
    my $pad   = _pad($indent);
    my $inner = _pad($indent + 1);
    my @items;
    for my $entry (@$decorators) {
        push @items, encode_one_decorator_entry($entry, $indent + 1);
    }
    return "[\n" . join(",\n", map { "$inner$_" } @items) . "\n$pad]";
}

sub encode_one_decorator_entry {
    my ($entry, $indent) = @_;
    my $pad   = _pad($indent);
    my $inner = _pad($indent + 1);
    my @parts;

    # path
    my $path = $entry->{path};
    if (!@$path) {
        push @parts, "${inner}\"path\": []";
    } else {
        my $pi = _pad($indent + 2);
        my @psegs;
        for my $seg (@$path) {
            if (defined $seg->{key}) {
                push @psegs, "$pi" . "{\"key\": " . quote_json($seg->{key}) . "}";
            } else {
                push @psegs, "$pi" . "{\"index\": $seg->{index}}";
            }
        }
        push @parts, "${inner}\"path\": [\n" . join(",\n", @psegs) . "\n${inner}]";
    }

    # calls (keyed by sigil)
    my $calls = $entry->{calls};
    my @sigils = sort keys %$calls;
    if (!@sigils) {
        push @parts, "${inner}\"calls\": {}";
    } else {
        my $ci = _pad($indent + 2);
        my @cparts;
        for my $sig (@sigils) {
            my $call_list = $calls->{$sig};
            my @call_jsons;
            for my $call (@$call_list) {
                push @call_jsons, encode_one_call($call, $indent + 3);
            }
            my $cii = _pad($indent + 3);
            push @cparts, "$ci" . quote_json($sig) . ": [\n"
                . join(",\n", map { "$cii$_" } @call_jsons)
                . "\n$ci]";
        }
        push @parts, "${inner}\"calls\": {\n" . join(",\n", @cparts) . "\n${inner}}";
    }

    # comments (always empty for now)
    push @parts, "${inner}\"comments\": []";

    return "{\n" . join(",\n", @parts) . "\n${pad}}";
}

sub encode_one_call {
    my ($call, $indent) = @_;
    my $pad   = _pad($indent);
    my $inner = _pad($indent + 1);
    my @parts;

    push @parts, "${inner}\"family\": " . quote_json($call->{family} // '');
    push @parts, "${inner}\"fn\": " . quote_json($call->{fn} // '');
    push @parts, "${inner}\"ns\": " . (defined $call->{ns} ? quote_json($call->{ns}) : 'null');
    push @parts, "${inner}\"position\": " . quote_json($call->{position} // 'inner');

    my $params = $call->{params} // [];
    if (!@$params) {
        push @parts, "${inner}\"params\": []";
    } else {
        my $pi = _pad($indent + 2);
        my @pjsons;
        for my $pg (@$params) {
            push @pjsons, encode_param_group($pg, $indent + 2);
        }
        push @parts, "${inner}\"params\": [\n"
            . join(",\n", map { "$pi$_" } @pjsons)
            . "\n${inner}]";
    }

    push @parts, "${inner}\"params_dec\": []";

    return "{\n" . join(",\n", @parts) . "\n${pad}}";
}

sub encode_param_group {
    my ($pg, $indent) = @_;
    my $pad   = _pad($indent);
    my $inner = _pad($indent + 1);
    my $kind  = $pg->{kind};
    my $val   = $pg->{value};

    if ($kind eq 'named') {
        my $val_json = encode_json_value($val, $indent + 1);
        return "{\n${inner}\"kind\": \"named\",\n${inner}\"value\": $val_json\n${pad}}";
    } else {
        my $val_json = encode_json_value($val, $indent + 1);
        return "{\n${inner}\"kind\": \"positional\",\n${inner}\"value\": $val_json\n${pad}}";
    }
}
