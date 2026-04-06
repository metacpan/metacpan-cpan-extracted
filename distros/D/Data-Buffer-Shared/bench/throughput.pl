#!/usr/bin/env perl
# Benchmark: single-process throughput for all operation types
use strict;
use warnings;
use Time::HiRes qw(time);

use Data::Buffer::Shared::I64;
use Data::Buffer::Shared::F64;
use Data::Buffer::Shared::Str;

my $n = $ARGV[0] || 1_000_000;
my $cap = 10_000;

sub bench {
    my ($label, $code) = @_;
    my $t0 = time();
    $code->();
    my $elapsed = time() - $t0;
    printf "%-30s %8.0f ops/sec  (%.3fs for %d ops)\n",
        $label, $n / $elapsed, $elapsed, $n;
}

print "=== I64 ($n ops, $cap elements) ===\n";
{
    my $buf = Data::Buffer::Shared::I64->new_anon($cap);

    bench "i64 set (lock-free)" => sub {
        for my $i (1..$n) { $buf->set($i % $cap, $i) }
    };
    bench "i64 get (lock-free)" => sub {
        my $v;
        for my $i (1..$n) { $v = $buf->get($i % $cap) }
    };
    bench "i64 incr (atomic)" => sub {
        for my $i (1..$n) { $buf->incr($i % $cap) }
    };
    bench "i64 add (atomic)" => sub {
        for my $i (1..$n) { $buf->add($i % $cap, 1) }
    };
    bench "i64 cas (atomic)" => sub {
        for my $i (1..$n) { $buf->cas($i % $cap, $buf->get($i % $cap), $i) }
    };
    bench "i64 cmpxchg (atomic)" => sub {
        for my $i (1..$n) { $buf->cmpxchg($i % $cap, $buf->get($i % $cap), $i) }
    };
    bench "i64 atomic_or" => sub {
        for my $i (1..$n) { $buf->atomic_or($i % $cap, 1) }
    };

    my $slice_n = int($n / 100);
    bench "i64 slice(100) read" => sub {
        for (1..$slice_n) { my @v = $buf->slice(0, 100) }
    };
    bench "i64 set_slice(100)" => sub {
        my @data = (42) x 100;
        for (1..$slice_n) { $buf->set_slice(0, @data) }
    };

    bench "i64 get_raw(800B)" => sub {
        for (1..$slice_n) { my $r = $buf->get_raw(0, 800) }
    };
    bench "i64 set_raw(800B)" => sub {
        my $data = pack("q<100", (42) x 100);
        for (1..$slice_n) { $buf->set_raw(0, $data) }
    };

    bench "i64 fill" => sub {
        for (1..1000) { $buf->fill(0) }
    };
    bench "i64 clear" => sub {
        for (1..1000) { $buf->clear }
    };
}

print "\n=== F64 ($n ops, $cap elements) ===\n";
{
    my $buf = Data::Buffer::Shared::F64->new_anon($cap);

    bench "f64 set (lock-free)" => sub {
        for my $i (1..$n) { $buf->set($i % $cap, 3.14) }
    };
    bench "f64 get (lock-free)" => sub {
        my $v;
        for my $i (1..$n) { $v = $buf->get($i % $cap) }
    };
}

print "\n=== Str/16B ($n ops, $cap elements) ===\n";
{
    my $buf = Data::Buffer::Shared::Str->new_anon($cap, 16);

    my $val = "hello world!!!!";  # 15 bytes
    bench "str set (locked)" => sub {
        for my $i (1..$n) { $buf->set($i % $cap, $val) }
    };
    bench "str get (seqlock)" => sub {
        my $v;
        for my $i (1..$n) { $v = $buf->get($i % $cap) }
    };
}

print "\n=== Keyword vs Method ($n ops) ===\n";
{
    my $buf = Data::Buffer::Shared::I64->new_anon($cap);

    bench "i64 method set" => sub {
        for my $i (1..$n) { $buf->set($i % $cap, $i) }
    };
    bench "i64 keyword set" => sub {
        for my $i (1..$n) { buf_i64_set $buf, $i % $cap, $i }
    };
    bench "i64 method get" => sub {
        my $v;
        for my $i (1..$n) { $v = $buf->get($i % $cap) }
    };
    bench "i64 keyword get" => sub {
        my $v;
        for my $i (1..$n) { $v = buf_i64_get $buf, $i % $cap }
    };
}
