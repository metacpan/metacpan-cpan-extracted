#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(cmpthese);

use Data::HashMap::II;
use Data::HashMap::SS;
use Tie::Hash::LRU;

my $N   = $ARGV[0] || 100_000;
my $CAP = int($N / 2);

print "=" x 70, "\n";
print "Data::HashMap vs Tie::Hash::LRU  (N=$N, LRU capacity=$CAP)\n";
print "=" x 70, "\n\n";

# ---- INSERT (fill to capacity, then churn) ----

print "-" x 70, "\n";
print "INSERT $N entries into LRU capacity $CAP (eviction churn)\n";
print "-" x 70, "\n";
cmpthese(-3, {
    'II_lru_kw' => sub {
        my $m = Data::HashMap::II->new($CAP);
        for my $i (1 .. $N) { hm_ii_put $m, $i, $i; }
    },
    'SS_lru_kw' => sub {
        my $m = Data::HashMap::SS->new($CAP);
        for my $i (1 .. $N) { hm_ss_put $m, "k$i", "v$i"; }
    },
    'THL_func' => sub {
        my $m = Tie::Hash::LRU->TIEHASH($CAP);
        for my $i (1 .. $N) { Tie::Hash::LRU::STORE($m, "k$i", "v$i"); }
    },
    'THL_meth' => sub {
        my $m = Tie::Hash::LRU->TIEHASH($CAP);
        for my $i (1 .. $N) { $m->STORE("k$i", "v$i"); }
    },
    'THL_tied' => sub {
        tie my %h, 'Tie::Hash::LRU', $CAP;
        for my $i (1 .. $N) { $h{"k$i"} = "v$i"; }
    },
});

# ---- Pre-fill maps for lookup benchmarks ----
my $m_ii = Data::HashMap::II->new($CAP);
my $m_ss = Data::HashMap::SS->new($CAP);
my $m_thl = Tie::Hash::LRU->TIEHASH($CAP);

# Fill with last $CAP keys (1..$CAP would be evicted)
my $start = $N - $CAP + 1;
for my $i ($start .. $N) {
    hm_ii_put $m_ii, $i, $i;
    hm_ss_put $m_ss, "k$i", "v$i";
    Tie::Hash::LRU::STORE($m_thl, "k$i", "v$i");
}

# ---- LOOKUP (all hits) ----

print "\n", "-" x 70, "\n";
print "LOOKUP $CAP entries (all hits, LRU promotion on each get)\n";
print "-" x 70, "\n";
cmpthese(-3, {
    'II_lru_kw' => sub {
        for my $i ($start .. $N) { my $v = hm_ii_get $m_ii, $i; }
    },
    'SS_lru_kw' => sub {
        for my $i ($start .. $N) { my $v = hm_ss_get $m_ss, "k$i"; }
    },
    'THL_func' => sub {
        for my $i ($start .. $N) { my $v = Tie::Hash::LRU::FETCH($m_thl, "k$i"); }
    },
    'THL_meth' => sub {
        for my $i ($start .. $N) { my $v = $m_thl->FETCH("k$i"); }
    },
});

# ---- DELETE ----

print "\n", "-" x 70, "\n";
print "INSERT + DELETE $CAP entries (LRU)\n";
print "-" x 70, "\n";
cmpthese(-3, {
    'II_lru_kw' => sub {
        my $m = Data::HashMap::II->new($CAP);
        for my $i (1 .. $CAP) { hm_ii_put $m, $i, $i; }
        for my $i (1 .. $CAP) { hm_ii_remove $m, $i; }
    },
    'SS_lru_kw' => sub {
        my $m = Data::HashMap::SS->new($CAP);
        for my $i (1 .. $CAP) { hm_ss_put $m, "k$i", "v$i"; }
        for my $i (1 .. $CAP) { hm_ss_remove $m, "k$i"; }
    },
    'THL_func' => sub {
        my $m = Tie::Hash::LRU->TIEHASH($CAP);
        for my $i (1 .. $CAP) { Tie::Hash::LRU::STORE($m, "k$i", "v$i"); }
        for my $i (1 .. $CAP) { Tie::Hash::LRU::DELETE($m, "k$i"); }
    },
});

# ---- EXISTS ----

print "\n", "-" x 70, "\n";
print "EXISTS $CAP lookups (all hits)\n";
print "-" x 70, "\n";
cmpthese(-3, {
    'II_lru_kw' => sub {
        for my $i ($start .. $N) { my $e = hm_ii_exists $m_ii, $i; }
    },
    'SS_lru_kw' => sub {
        for my $i ($start .. $N) { my $e = hm_ss_exists $m_ss, "k$i"; }
    },
    'THL_func' => sub {
        for my $i ($start .. $N) { my $e = Tie::Hash::LRU::EXISTS($m_thl, "k$i"); }
    },
});

# ---- MIXED WORKLOAD: 80% read, 20% write ----

print "\n", "-" x 70, "\n";
print "MIXED WORKLOAD: ${\ int($N*0.8) } reads + ${\ int($N*0.2) } writes\n";
print "-" x 70, "\n";
{
    my $reads  = int($N * 0.8);
    my $writes = int($N * 0.2);

    cmpthese(-3, {
        'II_lru_kw' => sub {
            my $m = Data::HashMap::II->new($CAP);
            for my $i (1 .. $CAP) { hm_ii_put $m, $i, $i; }
            for my $i (1 .. $reads)  { my $v = hm_ii_get $m, ($i % $CAP) + 1; }
            for my $i (1 .. $writes) { hm_ii_put $m, $CAP + $i, $i; }
        },
        'SS_lru_kw' => sub {
            my $m = Data::HashMap::SS->new($CAP);
            for my $i (1 .. $CAP) { hm_ss_put $m, "k$i", "v$i"; }
            for my $i (1 .. $reads)  { my $v = hm_ss_get $m, "k" . (($i % $CAP) + 1); }
            for my $i (1 .. $writes) { hm_ss_put $m, "k" . ($CAP + $i), "v$i"; }
        },
        'THL_func' => sub {
            my $m = Tie::Hash::LRU->TIEHASH($CAP);
            for my $i (1 .. $CAP) { Tie::Hash::LRU::STORE($m, "k$i", "v$i"); }
            for my $i (1 .. $reads)  { my $v = Tie::Hash::LRU::FETCH($m, "k" . (($i % $CAP) + 1)); }
            for my $i (1 .. $writes) { Tie::Hash::LRU::STORE($m, "k" . ($CAP + $i), "v$i"); }
        },
    });
}

# ---- MEMORY (separate processes, transient keys/values) ----
#
# Each measurement spawns a fresh perl process that:
#   1. loads only the needed module
#   2. measures RSS before and after filling the map
#   3. prints the delta
#
# No fork COW artifacts — each process starts clean.

print "\n", "=" x 70, "\n";
print "MEMORY: $CAP entries, separate processes (bytes per entry)\n";
print "=" x 70, "\n\n";

sub measure_memory_proc {
    my ($label, $code, $n) = @_;
    $n //= $CAP;

    my $script = <<'PREAMBLE';
use strict;
use warnings;
sub rss_kb {
    if ($^O eq 'linux') {
        open my $fh, '<', "/proc/$$/statm" or return 0;
        my $line = <$fh>; close $fh;
        my @f = split /\s+/, $line;
        return $f[1] * 4;
    }
    my $out = `ps -o rss= -p $$` // ''; chomp $out;
    return ($out =~ /^(\d+)$/) ? $1 : 0;
}
PREAMBLE
    $script .= $code;

    open my $ph, '-|', $^X, '-Mblib', '-e', $script or die "spawn: $!";
    my $out = <$ph>;
    close $ph;
    chomp $out;
    if ($out =~ /^(\d+)$/) {
        my $delta_kb = $1;
        my $bpe = $delta_kb > 0 ? ($delta_kb * 1024) / $n : 0;
        printf "  %-14s  %8d KB  (%5.1f bytes/entry)\n", $label, $delta_kb, $bpe;
    } else {
        printf "  %-14s  FAILED: %s\n", $label, $out;
    }
}

measure_memory_proc('II_lru', <<"CODE");
use Data::HashMap::II;
my \$n = $CAP;
my \$before = rss_kb();
my \$m = Data::HashMap::II->new(\$n);
for my \$i (1 .. \$n) { hm_ii_put \$m, \$i, \$i; }
my \$after = rss_kb();
print \$after - \$before, "\\n";
CODE

measure_memory_proc('SS_lru', <<"CODE");
use Data::HashMap::SS;
my \$n = $CAP;
my \$before = rss_kb();
my \$m = Data::HashMap::SS->new(\$n);
for my \$i (1 .. \$n) {
    my \$k = "key_" . sprintf("%08d", \$i);
    my \$v = "val_" . sprintf("%08d", \$i);
    hm_ss_put \$m, \$k, \$v;
}
my \$after = rss_kb();
print \$after - \$before, "\\n";
CODE

measure_memory_proc('THL', <<"CODE");
use Tie::Hash::LRU;
my \$n = $CAP;
my \$before = rss_kb();
my \$m = Tie::Hash::LRU->TIEHASH(\$n);
for my \$i (1 .. \$n) {
    my \$k = "key_" . sprintf("%08d", \$i);
    my \$v = "val_" . sprintf("%08d", \$i);
    Tie::Hash::LRU::STORE(\$m, \$k, \$v);
}
my \$after = rss_kb();
print \$after - \$before, "\\n";
CODE

measure_memory_proc('perl_%h', <<"CODE");
my \$n = $CAP;
my \$before = rss_kb();
my \%h;
for my \$i (1 .. \$n) {
    my \$k = "key_" . sprintf("%08d", \$i);
    my \$v = "val_" . sprintf("%08d", \$i);
    \$h{\$k} = \$v;
}
my \$after = rss_kb();
print \$after - \$before, "\\n";
CODE

print "\nDone.\n";
