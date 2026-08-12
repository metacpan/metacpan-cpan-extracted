#!/usr/bin/env perl
# Author test — runs valgrind against scenarios that previously leaked.
# Skipped unless RELEASE_TESTING=1 and valgrind is available.

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

plan skip_all => 'set RELEASE_TESTING=1 to run leak tests'
    unless $ENV{RELEASE_TESTING};

my $vg = `which valgrind 2>/dev/null`;
chomp $vg;
plan skip_all => 'valgrind not in PATH' unless $vg && -x $vg;

# Resolve the actual perl interpreter (skip plenv shim since valgrind doesn't
# follow exec by default).
my $perl = $^X;
if ($perl =~ m{plenv/shims}) {
    chomp(my $real = `$perl -e 'print \$^X'`);
    $perl = $real if -x $real;
}

sub run_under_valgrind {
    my ($script) = @_;
    my ($fh, $name) = tempfile(SUFFIX => '.pl', UNLINK => 1);
    print $fh $script;
    close $fh;

    # NB: no -q. It suppresses the LEAK SUMMARY block, the only place the
    # "definitely lost: N bytes" line these assertions match appears - so
    # with -q every check in this file passed unconditionally.
    my $cmd = "$vg --leak-check=full --error-exitcode=99 $perl -Mblib '$name' 2>&1";
    my $output = `$cmd`;
    return $output;
}

# Assert no definitely-lost bytes. A missing summary means the valgrind
# invocation went wrong, which must fail rather than silently pass.
sub assert_no_leaks {
    my ($out, $label) = @_;
    my ($lost) = $out =~ /definitely lost:\s*([\d,]+) bytes/;
    if (!defined $lost) {
        fail("$label (no valgrind leak summary found - check invocation)");
        diag(substr($out, 0, 2000));
        return;
    }
    $lost =~ tr/,//d;
    is($lost, 0, $label) or diag(_leak_summary($out));
    return;
}

# ---- scenarios ------------------------------------------------------------

# 1) Repeated successful encodes must not leak.
{
    my $out = run_under_valgrind(<<'PERL');
use ClickHouse::Encoder;
my $enc = ClickHouse::Encoder->new(columns => [
    ['a', 'Array(Nullable(Tuple(String, Decimal128(2))))'],
    ['b', "Enum16('foo'=1, 'bar'=2)"],
]);
for (1..200) {
    $enc->encode([[[['hi', '1.23'], undef], 'foo'], [[], 'bar']]);
}
PERL
    assert_no_leaks($out, 'no leaks on repeated successful encode');
}

# 2) Construct-time errors must not leak.
{
    my $out = run_under_valgrind(<<'PERL');
use ClickHouse::Encoder;
for (1..50) {
    eval { ClickHouse::Encoder->new(columns => [['v', 'UnknownType']]) };
    eval { ClickHouse::Encoder->new(columns => [['v', 'Tuple(UnknownType)']]) };
    eval { ClickHouse::Encoder->new(columns => [['v', 'Tuple(Int32, UnknownInner)']]) };
    eval { ClickHouse::Encoder->new(columns => [['v', "Enum8('' = 1)"]]) };
    eval { ClickHouse::Encoder->new(columns => [['v', 'Nullable(Nullable(Int32))']]) };
    eval { ClickHouse::Encoder->new(columns => [['v', 'FixedString(0)']]) };
    eval { ClickHouse::Encoder->new(columns => [['v', "Enum8('big' = 999)"]]) };
}
PERL
    assert_no_leaks($out, 'no leaks on constructor errors');
}

# 3) Encode-time errors must not leak.
{
    my $out = run_under_valgrind(<<'PERL');
use ClickHouse::Encoder;
my $e = ClickHouse::Encoder->new(columns => [['a', 'UInt8'], ['b', 'Array(Int32)']]);
for (1..100) {
    eval { $e->encode([[1]]) };                       # short row
    eval { $e->encode([[1, 'not-array']]) };          # bad inner type
    eval { $e->encode([[1, [1,2]], [2]]) };           # row 1 short
}
PERL
    assert_no_leaks($out, 'no leaks on encode errors');
}

# 4) Decode-time errors must not leak. This file covered only encode for a
#    long time, which is how a leak of the half-built column plus its
#    TypeInfo survived on every decode croak.
{
    my $out = run_under_valgrind(<<'PERL');
use ClickHouse::Encoder;
sub varint { my $v = shift; my $o=''; while ($v >= 0x80) { $o .= chr(($v & 0x7f)|0x80); $v >>= 7 } $o . chr($v) }
sub lenpfx { my $s = shift; varint(length $s) . $s }

# Truncate a valid block of each interesting type just short of complete,
# so the decoder is deep into the column when it runs out of bytes.
my @truncated;
for my $type ('String', 'Array(Int64)', 'Nullable(String)',
              'Tuple(Int32, String)', 'Map(String, Int32)',
              'LowCardinality(String)', 'Variant(Int32, String)',
              'JSON', 'Dynamic') {
    my $enc = eval { ClickHouse::Encoder->new(columns => [['c', $type]]) } or next;
    my @rows = $type eq 'JSON'          ? ([{a=>1,b=>'x'}], [{tags=>[1,2]}])
             : $type eq 'Dynamic'       ? ([1], ['x'], [[1,2]])
             : $type =~ /^Variant/      ? ([[0,42]], [[1,'hi']])
             : $type =~ /^Map/          ? ([{a=>1}], [{b=>2}])
             : $type =~ /^Tuple/        ? ([[1,'x']], [[2,'y']])
             : $type =~ /^Array/        ? ([[1,2,3]], [[4]])
             : $type eq 'Nullable(String)' ? (['x'], [undef])
             :                            (['aa'], ['bb']);
    my $b = eval { $enc->encode(\@rows) } or next;
    push @truncated, substr($b, 0, length($b) - 1);
}

# Also exercise the structural rejections added for malformed wire data.
push @truncated,
    varint(0) . varint(1000),                       # ncols=0, nrows>0
    varint(1) . varint(0) . lenpfx('c')
              . lenpfx(('Array(' x 500) . 'Int32' . (')' x 500));  # too deep

for (1 .. 20) {
    eval { ClickHouse::Encoder->decode_block($_) } for @truncated;
    eval { ClickHouse::Encoder->decode_rows($_) }  for @truncated;
}
PERL
    assert_no_leaks($out, 'no leaks on decode errors');
}

done_testing();

sub _leak_summary {
    my ($out) = @_;
    my @lines = grep { /lost|HEAP SUMMARY|in use at exit/ } split /\n/, $out;
    return join("\n", @lines);
}
