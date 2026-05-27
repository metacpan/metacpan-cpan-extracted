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

    my $cmd = "$vg --leak-check=full --error-exitcode=99 -q $perl -Mblib '$name' 2>&1";
    my $output = `$cmd`;
    return $output;
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
    unlike($out, qr/definitely lost: [1-9]/, 'no leaks on repeated successful encode')
        or diag(_leak_summary($out));
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
    unlike($out, qr/definitely lost: [1-9]/, 'no leaks on constructor errors')
        or diag(_leak_summary($out));
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
    unlike($out, qr/definitely lost: [1-9]/, 'no leaks on encode errors')
        or diag(_leak_summary($out));
}

done_testing();

sub _leak_summary {
    my ($out) = @_;
    my @lines = grep { /lost|HEAP SUMMARY|in use at exit/ } split /\n/, $out;
    return join("\n", @lines);
}
