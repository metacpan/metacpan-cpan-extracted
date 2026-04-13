#!/usr/bin/env perl
# Single-process throughput benchmark for all operations and variants

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Time::HiRes qw(time);
use Data::Pool::Shared;

my $N = shift || 1_000_000;

sub bench {
    my ($label, $code) = @_;
    my $t0 = time;
    $code->();
    my $dt = time - $t0;
    printf "  %-40s %10.0f/s  (%.3fs)\n", $label, $N / $dt, $dt;
}

printf "Data::Pool::Shared single-process benchmark (%d ops)\n\n", $N;

# --- I64 ---

print "I64:\n";
my $i64 = Data::Pool::Shared::I64->new(undef, $N < 1000 ? $N : 1000);

# alloc/free cycle
bench "alloc + free" => sub {
    for (1..$N) {
        my $s = $i64->try_alloc;
        last unless defined $s;
        $i64->free($s);
    }
};

# pre-alloc, then get/set
my @slots;
for (1..100) { push @slots, $i64->alloc }
$i64->set($_, 0) for @slots;

bench "set" => sub {
    for (1..$N) {
        $i64->set($slots[$_ % 100], $_);
    }
};

bench "get" => sub {
    my $v;
    for (1..$N) {
        $v = $i64->get($slots[$_ % 100]);
    }
};

bench "add" => sub {
    for (1..$N) {
        $i64->add($slots[$_ % 100], 1);
    }
};

bench "incr" => sub {
    for (1..$N) {
        $i64->incr($slots[$_ % 100]);
    }
};

$i64->set($slots[0], 0);
bench "cas (succeed)" => sub {
    for my $i (0..$N-1) {
        $i64->cas($slots[0], $i, $i + 1);
    }
};

bench "is_allocated" => sub {
    for (1..$N) {
        $i64->is_allocated($slots[$_ % 100]);
    }
};

$i64->free($_) for @slots;

# alloc_set + free
bench "alloc_set + free" => sub {
    for (1..$N) {
        my $s = $i64->try_alloc_set($_);
        last unless defined $s;
        $i64->free($s);
    }
};

print "\n";

# --- F64 ---

print "F64:\n";
my $f64 = Data::Pool::Shared::F64->new(undef, 100);
@slots = ();
for (1..100) { push @slots, $f64->alloc }

bench "set" => sub {
    for (1..$N) {
        $f64->set($slots[$_ % 100], $_ * 0.1);
    }
};

bench "get" => sub {
    my $v;
    for (1..$N) {
        $v = $f64->get($slots[$_ % 100]);
    }
};

$f64->free($_) for @slots;
print "\n";

# --- I32 ---

print "I32:\n";
my $i32 = Data::Pool::Shared::I32->new(undef, 100);
@slots = ();
for (1..100) { push @slots, $i32->alloc }
$i32->set($_, 0) for @slots;

bench "set" => sub {
    for (1..$N) {
        $i32->set($slots[$_ % 100], $_ & 0x7FFFFFFF);
    }
};

bench "get" => sub {
    my $v;
    for (1..$N) {
        $v = $i32->get($slots[$_ % 100]);
    }
};

bench "add" => sub {
    for (1..$N) {
        $i32->add($slots[$_ % 100], 1);
    }
};

$i32->free($_) for @slots;
print "\n";

# --- Str ---

print "Str:\n";
my $str = Data::Pool::Shared::Str->new(undef, 100, 64);
@slots = ();
for (1..100) { push @slots, $str->alloc }

my $teststr = "hello world " x 4;  # 48 bytes
bench "set (48B)" => sub {
    for (1..$N) {
        $str->set($slots[$_ % 100], $teststr);
    }
};

bench "get (48B)" => sub {
    my $v;
    for (1..$N) {
        $v = $str->get($slots[$_ % 100]);
    }
};

$str->free($_) for @slots;
print "\n";

# --- Raw ---

print "Raw (32B):\n";
my $raw = Data::Pool::Shared->new(undef, 100, 32);
@slots = ();
for (1..100) { push @slots, $raw->alloc }

my $rawdata = "x" x 32;
bench "set" => sub {
    for (1..$N) {
        $raw->set($slots[$_ % 100], $rawdata);
    }
};

bench "get" => sub {
    my $v;
    for (1..$N) {
        $v = $raw->get($slots[$_ % 100]);
    }
};

$raw->free($_) for @slots;
