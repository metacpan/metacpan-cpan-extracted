#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(cmpthese);

use Data::HashMap::I16;
use Data::HashMap::I32;
use Data::HashMap::II;
use Data::HashMap::IS;
use Data::HashMap::SI;
use Data::HashMap::SS;
use Data::HashMap::IA;
use Data::HashMap::SA;
use Data::HashMap::I32A;
use Data::HashMap::I16A;

my $N = $ARGV[0] || 100_000;
my $N16 = $N > 30_000 ? 30_000 : $N;

print "=" x 70, "\n";
print "EACH / ITERATOR Benchmark  (N=$N)\n";
print "=" x 70, "\n\n";

# Pre-fill maps
my $m_i16 = Data::HashMap::I16->new();
hm_i16_put $m_i16, $_, $_ for 1 .. $N16;

my $m_i32 = Data::HashMap::I32->new();
hm_i32_put $m_i32, $_, $_ for 1 .. $N;

my $m_ii = Data::HashMap::II->new();
hm_ii_put $m_ii, $_, $_ for 1 .. $N;

my $m_is = Data::HashMap::IS->new();
hm_is_put $m_is, $_, "v$_" for 1 .. $N;

my $m_si = Data::HashMap::SI->new();
hm_si_put $m_si, "k$_", $_ for 1 .. $N;

my $m_ss = Data::HashMap::SS->new();
hm_ss_put $m_ss, "k$_", "v$_" for 1 .. $N;

my $m_ia = Data::HashMap::IA->new();
hm_ia_put $m_ia, $_, "v$_" for 1 .. $N;

my $m_sa = Data::HashMap::SA->new();
hm_sa_put $m_sa, "k$_", "v$_" for 1 .. $N;

my $m_i32a = Data::HashMap::I32A->new();
hm_i32a_put $m_i32a, $_, "v$_" for 1 .. $N;

my $m_i16a = Data::HashMap::I16A->new();
hm_i16a_put $m_i16a, $_, "v$_" for 1 .. $N16;

# Perl hashes
my %h_ii; $h_ii{$_} = $_ for 1 .. $N;
my %h_ss; $h_ss{"k$_"} = "v$_" for 1 .. $N;

print "-" x 70, "\n";
print "ITERATE all $N entries with each() (iterations/sec)\n";
print "-" x 70, "\n";
cmpthese(-3, {
    'perl_ii' => sub {
        while (my ($k, $v) = each %h_ii) { }
    },
    'perl_ss' => sub {
        while (my ($k, $v) = each %h_ss) { }
    },
    'I16' => sub {
        while (my ($k, $v) = hm_i16_each $m_i16) { }
    },
    'I32' => sub {
        while (my ($k, $v) = hm_i32_each $m_i32) { }
    },
    'II' => sub {
        while (my ($k, $v) = hm_ii_each $m_ii) { }
    },
    'IS' => sub {
        while (my ($k, $v) = hm_is_each $m_is) { }
    },
    'SI' => sub {
        while (my ($k, $v) = hm_si_each $m_si) { }
    },
    'SS' => sub {
        while (my ($k, $v) = hm_ss_each $m_ss) { }
    },
    'IA' => sub {
        while (my ($k, $v) = hm_ia_each $m_ia) { }
    },
    'SA' => sub {
        while (my ($k, $v) = hm_sa_each $m_sa) { }
    },
    'I32A' => sub {
        while (my ($k, $v) = hm_i32a_each $m_i32a) { }
    },
    'I16A' => sub {
        while (my ($k, $v) = hm_i16a_each $m_i16a) { }
    },
});

print "\n";
print "-" x 70, "\n";
print "ITERATE all $N entries with keys() (iterations/sec)\n";
print "-" x 70, "\n";
cmpthese(-3, {
    'perl_ii' => sub {
        my @k = keys %h_ii;
    },
    'perl_ss' => sub {
        my @k = keys %h_ss;
    },
    'II' => sub {
        my @k = hm_ii_keys $m_ii;
    },
    'SS' => sub {
        my @k = hm_ss_keys $m_ss;
    },
    'I32' => sub {
        my @k = hm_i32_keys $m_i32;
    },
    'SI' => sub {
        my @k = hm_si_keys $m_si;
    },
});

print "\n";
print "-" x 70, "\n";
print "ITERATE all $N entries with items() vs each-in-loop (iterations/sec)\n";
print "-" x 70, "\n";
cmpthese(-3, {
    'perl_each' => sub {
        while (my ($k, $v) = each %h_ii) { }
    },
    'perl_kv' => sub {
        my @kv = %h_ii;
    },
    'II_each' => sub {
        while (my ($k, $v) = hm_ii_each $m_ii) { }
    },
    'II_items' => sub {
        my @kv = hm_ii_items $m_ii;
    },
    'SS_each' => sub {
        while (my ($k, $v) = hm_ss_each $m_ss) { }
    },
    'SS_items' => sub {
        my @kv = hm_ss_items $m_ss;
    },
});
