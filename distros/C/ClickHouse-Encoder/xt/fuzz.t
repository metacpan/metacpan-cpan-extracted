#!/usr/bin/env perl
# Fuzz test: generate random schemas + rows, encode, send to a real ClickHouse
# server, assert the server accepts the buffer. Catches drift between this
# encoder's wire format and the server's parser for combinations not covered
# by t/live.t. Skipped unless RELEASE_TESTING=1 and TEST_CLICKHOUSE_PORT is set.

use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch', 't/lib';
use TestCH qw(split_paren_list);
*_split_paren_list = \&split_paren_list;

plan skip_all => 'set RELEASE_TESTING=1 to run fuzz tests'
    unless $ENV{RELEASE_TESTING};

my $port = $ENV{TEST_CLICKHOUSE_PORT};
plan skip_all => 'set TEST_CLICKHOUSE_PORT to run fuzz tests'
    unless defined $port;

unless (system("clickhouse-client --port $port --query 'select 1' >/dev/null 2>&1") == 0) {
    plan skip_all => "ClickHouse not reachable on port $port";
}

require ClickHouse::Encoder;

my $iters = $ENV{FUZZ_ITERS} // 30;
plan tests => $iters;

my @leaf_types = (
    'Int8','Int16','Int32','Int64',
    'UInt8','UInt16','UInt32','UInt64',
    'Float32','Float64',
    'String','FixedString(8)',
    'Date','DateTime','DateTime64(3)',
    'Decimal32(2)','Decimal64(4)',
);

sub random_type {
    my ($depth) = @_;
    $depth //= 0;
    my $r = rand();
    if ($depth < 2 && $r < 0.18) {
        return 'Array(' . random_type($depth + 1) . ')';
    }
    if ($depth < 2 && $r < 0.30) {
        my $n = 2 + int(rand(3));
        return 'Tuple(' . join(', ', map { random_type($depth + 1) } 1..$n) . ')';
    }
    if ($depth < 2 && $r < 0.45) {
        my $inner = random_type($depth + 1);
        return "Nullable($inner)" if $inner !~ /^(Array|Tuple|Nullable)/;
    }
    return $leaf_types[int(rand(scalar @leaf_types))];
}

sub random_value {
    my ($type, $depth) = @_;
    $depth //= 0;
    if    ($type =~ /^U?Int8$/)         { return int(rand(100)) }
    elsif ($type =~ /^U?Int16$/)        { return int(rand(30000)) }
    elsif ($type =~ /^U?Int32$/)        { return int(rand(1_000_000)) }
    elsif ($type =~ /^U?Int64$/)        { return int(rand(1_000_000_000)) }
    elsif ($type =~ /^Float/)           { return rand() * 1000 - 500 }
    elsif ($type eq 'String')           { return 'fuzz_' . int(rand(10_000)) }
    elsif ($type =~ /^FixedString\((\d+)\)$/) {
        my $n = $1;
        my $s = 'x' x int(rand($n + 1));
        return $s;
    }
    elsif ($type eq 'Date')             { return int(rand(20_000)) }
    elsif ($type eq 'DateTime')         { return int(rand(2_000_000_000)) }
    elsif ($type =~ /^DateTime64/)      { return int(rand(2_000_000_000_000)) }
    elsif ($type =~ /^Decimal/)         { return sprintf('%.2f', rand(10_000) - 5000) }
    elsif ($type =~ /^Array\((.+)\)$/) {
        my $inner = $1;
        my $n = int(rand(4));
        return [map { random_value($inner, $depth+1) } 1..$n];
    }
    elsif ($type =~ /^Tuple\((.+)\)$/) {
        my $body = $1;
        my @parts = _split_paren_list($body);
        return [map { random_value($_, $depth+1) } @parts];
    }
    elsif ($type =~ /^Nullable\((.+)\)$/) {
        return rand() < 0.3 ? undef : random_value($1, $depth+1);
    }
    die "Unknown type for value gen: $type";
}


my $seed = defined $ENV{FUZZ_SEED} ? $ENV{FUZZ_SEED} : time;
srand($seed);
diag("fuzz seed: $seed (set FUZZ_SEED=$seed to replay)");

for my $iter (1..$iters) {
    my $ncols = 1 + int(rand(4));
    my @cols  = map { ["c$_", random_type()] } 0..$ncols-1;
    my $nrows = 1 + int(rand(20));
    my @rows  = map {
        [map { random_value($_->[1]) } @cols]
    } 1..$nrows;

    my $enc = eval { ClickHouse::Encoder->new(columns => \@cols) };
    if (!$enc) {
        fail("iter $iter: encoder construction failed: $@");
        diag("schema: " . join(', ', map { "@$_" } @cols));
        next;
    }
    my $bin = eval { $enc->encode(\@rows) };
    if (!defined $bin) {
        fail("iter $iter: encode failed: $@");
        diag("schema: " . join(', ', map { "@$_" } @cols));
        next;
    }

    # Build schema and test against ClickHouse.
    my $col_defs = join(', ', map { "$_->[0] $_->[1]" } @cols);
    system("clickhouse-client --port $port --query 'drop table if exists fuzz_test' >/dev/null 2>&1");
    my $rc = system("clickhouse-client --port $port --query 'create table fuzz_test ($col_defs) engine = Memory' >/dev/null 2>&1");
    if ($rc != 0) {
        diag("iter $iter: skip (CH didn't accept schema): $col_defs");
        ok(1, "iter $iter: schema unsupported (skip)");
        next;
    }

    # List form so $port (an env var) isn't shell-interpreted; redirect
    # stderr in Perl rather than via the shell.
    my $err_fh;
    open $err_fh, '>', '/tmp/fuzz.err' or die "open /tmp/fuzz.err: $!";
    defined(my $pid = open my $fh, '|-') or die "fork: $!";
    if ($pid == 0) {
        open STDERR, '>&', $err_fh or die "redirect: $!";
        exec 'clickhouse-client', '--port', $port, '--query',
             "insert into fuzz_test format native";
        die "exec: $!";
    }
    close $err_fh;
    binmode $fh;
    print $fh $bin;
    close $fh;
    my $insert_ok = ($? == 0);

    open my $count_fh, '-|', 'clickhouse-client', '--port', $port,
        '--query', 'select count() from fuzz_test'
        or die "count query: $!";
    my $count = do { local $/; <$count_fh> };
    close $count_fh;
    chomp $count;

    if (!$insert_ok || $count != $nrows) {
        my $err = do { local (@ARGV, $/) = '/tmp/fuzz.err'; <> };
        fail("iter $iter: CH rejected our buffer (got $count rows, expected $nrows)");
        diag("schema: $col_defs");
        diag("error:  $err") if $err;
    } else {
        pass("iter $iter: $ncols cols × $nrows rows accepted");
    }
}

system("clickhouse-client --port $port --query 'drop table if exists fuzz_test' >/dev/null 2>&1");
