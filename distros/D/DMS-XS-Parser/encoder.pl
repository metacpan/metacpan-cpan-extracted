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
use DMS::XS::Parser;
use DMS::Tier1;
use Tie::IxHash;
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
# - --ignore-order needs DMS::UnorderedTable wrapping in Perl.
# The C fast path handles empty stdin by emitting "{}" and exiting 0,
# which still satisfies the "empty stdin → exit 0" probe contract.
if ($tier == 1 && !$roundtrip && $bench_iters == 0) {
    binmode(STDOUT, ':raw:utf8');
    my $src = do { local $/; <STDIN> };
    if (!defined $src || $src =~ /\A\s*\z/) { exit 0; }
    my $t1_doc;
    eval { $t1_doc = DMS::Tier1::decode_t1($src); };
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
    eval { DMS::XS::Parser::encode_stdin_to_stdout(); };
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
# replacing every table with a DMS::UnorderedTable plain hashref. Front
# matter remains ordered (per spec).
#
# SPEC §"Parsing modes — full and lite": `--mode lite` (or DMS_MODE=lite)
# routes through decode_document_lite even on the tagged-JSON path. Tagged
# JSON is mode-invariant (same value tree); the dispatch lets conformance
# exercise both parsers under one driver.
eval {
    if ($lite && $ignore_order) {
        $doc = DMS::XS::Parser::decode_lite_document_unordered($src);
    }
    elsif ($lite) {
        $doc = DMS::XS::Parser::decode_document_lite($src);
    }
    elsif ($ignore_order) {
        $doc = DMS::XS::Parser::decode_document_unordered($src);
    }
    else {
        $doc = DMS::XS::Parser::decode_document($src);
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
            ? DMS::XS::Parser::encode_lite($doc)
            : DMS::XS::Parser::encode($doc);
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
            ? DMS::XS::Parser::encode_lite($doc)
            : DMS::XS::Parser::encode($doc);
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
        if ($cls eq 'DMS::UnorderedTable') {
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
        if ($cls eq 'DMS::Bool') {
            my $bv = $v->value ? 'true' : 'false';
            return tagged_json('bool', $bv, $indent);
        }
        if ($cls eq 'DMS::Integer') {
            return tagged_json('integer', $v->value->bstr, $indent);
        }
        if ($cls eq 'DMS::Float') {
            return tagged_json('float', shortest_float($v->value), $indent);
        }
        if ($cls eq 'DMS::OffsetDateTime') {
            return tagged_json('offset-datetime', $v->value, $indent);
        }
        if ($cls eq 'DMS::LocalDateTime') {
            return tagged_json('local-datetime', $v->value, $indent);
        }
        if ($cls eq 'DMS::LocalDate') {
            return tagged_json('local-date', $v->value, $indent);
        }
        if ($cls eq 'DMS::LocalTime') {
            return tagged_json('local-time', $v->value, $indent);
        }
        die "unknown blessed value class $cls";
    }
    if (ref($v) eq 'HASH') {
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
    my $inner = '  ' x ($indent + 1);
    my $pad = '  ' x $indent;
    return "{\n${inner}\"type\": " . quote_json($t) . ",\n${inner}\"value\": " . quote_json($v) . "\n${pad}}";
}
