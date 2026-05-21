#!/usr/bin/env perl
# Benchmark: DMS::Parser (pure Perl) vs DMS::XS::Parser (C-backed).
#
# Reads a handful of representative fixtures from the conformance corpus
# and runs each through both parsers under Benchmark::cmpthese.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";        # pure-Perl DMS::Parser lives in ../
use lib "$FindBin::Bin/blib/lib";
use lib "$FindBin::Bin/blib/arch";
use DMS::Parser;
use DMS::XS::Parser;
use Benchmark qw(cmpthese timethese);

my $ROOT = "$FindBin::Bin/../../..";

# Representative fixtures covering small / medium / large / tier-1 features.
my @fixtures = (
    ["tiny int",            "$ROOT/tests/valid/int-dec/v0000.dms"],
    ["small table",         "$ROOT/tests/valid/combo/quad-000.dms"],
    ["flat-500 (big)",      "$ROOT/tests/valid/stress/flat-500.dms"],
    ["flow-array-1000",     "$ROOT/tests/valid/stress/flow-array-1000.dms"],
    ["depth-50",            "$ROOT/tests/valid/stress/depth-50.dms"],
    ["frontmatter keys-200","$ROOT/tests/valid/frontmatter-stress/keys-200.dms"],
    ["tier1 pure mod",      "$ROOT/tests/valid/tier1-user-mod/chain-upper-then-trim.dms"],
);

# Filter to what's actually present.
@fixtures = grep { -f $_->[1] } @fixtures;

# Build shared config with pure modifiers so tier-1 fixtures work on both.
my $pure_cfg = DMS::ParserConfig->new;
$pure_cfg->register_pure('my_upper',  \&mod_my_upper);
$pure_cfg->register_pure('my_repeat', \&mod_my_repeat);

my $xs_cfg = DMS::XS::ParserConfig->new;
$xs_cfg->register_pure('my_upper',  \&mod_my_upper);
$xs_cfg->register_pure('my_repeat', \&mod_my_repeat);

for my $f (@fixtures) {
    my ($label, $path) = @$f;
    open my $fh, '<', $path or do { warn "skip $path: $!\n"; next };
    local $/;
    my $src = <$fh>;
    close $fh;
    my $bytes = length $src;

    print "=" x 60, "\n";
    printf "%s  (%d bytes)\n", $label, $bytes;
    print "=" x 60, "\n";

    # Validate both parse successfully before benchmarking.
    my $ok = 1;
    for my $pair (
        ['pure', sub { DMS::Parser::parse_document_with_config($src, $pure_cfg) }],
        ['xs',   sub { DMS::XS::Parser::parse_document_with_config($src, $xs_cfg) }],
    ) {
        eval { $pair->[1]->() };
        if ($@) { warn "  $pair->[0] failed to parse: $@"; $ok = 0 }
    }
    unless ($ok) { print "  (skipped: parse failure)\n\n"; next }

    # Auto-tune iteration count: more iterations for faster fixtures.
    cmpthese(-2, {
        pure => sub { DMS::Parser::parse_document_with_config($src, $pure_cfg) },
        xs   => sub { DMS::XS::Parser::parse_document_with_config($src, $xs_cfg) },
    });
    print "\n";
}

sub mod_my_upper {
    my ($input, $params) = @_;
    die "my_upper takes no arguments"
        if defined($params) && ref($params) eq 'ARRAY' && @$params;
    die "my_upper expects a string value" if ref($input) ne '';
    return uc($input);
}

sub mod_my_repeat {
    my ($input, $params) = @_;
    die "my_repeat expects one non-negative integer argument"
        unless defined($params) && ref($params) eq 'ARRAY' && @$params == 1;
    my $arg = $params->[0];
    die "my_repeat expects one non-negative integer argument"
        unless ref($arg) eq 'DMS::Integer';
    my $bn = $arg->value;
    die "my_repeat expects one non-negative integer argument"
        if $bn->is_neg;
    my $n = int($bn->bstr);
    die "my_repeat expects a string value" if ref($input) ne '';
    return $input x $n;
}
