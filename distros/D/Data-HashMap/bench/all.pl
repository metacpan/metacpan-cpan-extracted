#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(cmpthese);
use POSIX ();

use Data::HashMap::I16;
use Data::HashMap::I16S;
use Data::HashMap::I32;
use Data::HashMap::I32S;
use Data::HashMap::II;
use Data::HashMap::IS;
use Data::HashMap::I16A;
use Data::HashMap::I32A;
use Data::HashMap::IA;
use Data::HashMap::SA;
use Data::HashMap::SI;
use Data::HashMap::SI16;
use Data::HashMap::SI32;
use Data::HashMap::SS;

my $N = $ARGV[0] || 100_000;
my $N16 = $N > 30_000 ? 30_000 : $N;  # int16 key/value range limit
my $MEM_N = $ARGV[1] || 1_000_000;
my $MEM_N16 = $MEM_N > 30_000 ? 30_000 : $MEM_N;

print "=" x 70, "\n";
print "Data::HashMap Benchmark  (N=$N, MEM_N=$MEM_N)\n";
print "=" x 70, "\n\n";

# --- Performance benchmarks ---

print "-" x 70, "\n";
print "INSERT $N entries\n";
print "-" x 70, "\n";
cmpthese(-3, {
    'I16' => sub {
        my $m = Data::HashMap::I16->new();
        for my $i (1 .. $N16) { hm_i16_put $m, $i, $i; }
    },
    'I16A' => sub {
        my $m = Data::HashMap::I16A->new();
        for my $i (1 .. $N16) { hm_i16a_put $m, $i, "v$i"; }
    },
    'I16S' => sub {
        my $m = Data::HashMap::I16S->new();
        for my $i (1 .. $N16) { hm_i16s_put $m, $i, "v$i"; }
    },
    'SI16' => sub {
        my $m = Data::HashMap::SI16->new();
        for my $i (1 .. $N16) { hm_si16_put $m, "k$i", $i; }
    },
    'I32' => sub {
        my $m = Data::HashMap::I32->new();
        for my $i (1 .. $N) { hm_i32_put $m, $i, $i; }
    },
    'II' => sub {
        my $m = Data::HashMap::II->new();
        for my $i (1 .. $N) { hm_ii_put $m, $i, $i; }
    },
    'I32A' => sub {
        my $m = Data::HashMap::I32A->new();
        for my $i (1 .. $N) { hm_i32a_put $m, $i, "v$i"; }
    },
    'I32S' => sub {
        my $m = Data::HashMap::I32S->new();
        for my $i (1 .. $N) { hm_i32s_put $m, $i, "v$i"; }
    },
    'IA' => sub {
        my $m = Data::HashMap::IA->new();
        for my $i (1 .. $N) { hm_ia_put $m, $i, "v$i"; }
    },
    'IS' => sub {
        my $m = Data::HashMap::IS->new();
        for my $i (1 .. $N) { hm_is_put $m, $i, "v$i"; }
    },
    'SA' => sub {
        my $m = Data::HashMap::SA->new();
        for my $i (1 .. $N) { hm_sa_put $m, "k$i", "v$i"; }
    },
    'SI32' => sub {
        my $m = Data::HashMap::SI32->new();
        for my $i (1 .. $N) { hm_si32_put $m, "k$i", $i; }
    },
    'SI' => sub {
        my $m = Data::HashMap::SI->new();
        for my $i (1 .. $N) { hm_si_put $m, "k$i", $i; }
    },
    'SS' => sub {
        my $m = Data::HashMap::SS->new();
        for my $i (1 .. $N) { hm_ss_put $m, "k$i", "v$i"; }
    },
    'perl_ii' => sub {
        my %h;
        for my $i (1 .. $N) { $h{$i} = $i; }
    },
    'perl_ss' => sub {
        my %h;
        for my $i (1 .. $N) { $h{"k$i"} = "v$i"; }
    },
});

# Pre-fill maps for lookup benchmarks
my $m_i16 = Data::HashMap::I16->new();
my $m_i16a = Data::HashMap::I16A->new();
my $m_i16s = Data::HashMap::I16S->new();
my $m_si16 = Data::HashMap::SI16->new();
my ($m_i32, $m_i32a, $m_i32s, $m_ii, $m_ia, $m_is, $m_sa, $m_si32, $m_si, $m_ss) = (
    Data::HashMap::I32->new(),
    Data::HashMap::I32A->new(),
    Data::HashMap::I32S->new(),
    Data::HashMap::II->new(),
    Data::HashMap::IA->new(),
    Data::HashMap::IS->new(),
    Data::HashMap::SA->new(),
    Data::HashMap::SI32->new(),
    Data::HashMap::SI->new(),
    Data::HashMap::SS->new(),
);
my (%h_ii, %h_ss);
for my $i (1 .. $N16) {
    hm_i16_put $m_i16, $i, $i;
    hm_i16a_put $m_i16a, $i, "v$i";
    hm_i16s_put $m_i16s, $i, "v$i";
    hm_si16_put $m_si16, "k$i", $i;
}
for my $i (1 .. $N) {
    hm_i32_put $m_i32, $i, $i;
    hm_i32a_put $m_i32a, $i, "v$i";
    hm_i32s_put $m_i32s, $i, "v$i";
    hm_ii_put $m_ii, $i, $i;
    hm_ia_put $m_ia, $i, "v$i";
    hm_is_put $m_is, $i, "v$i";
    hm_sa_put $m_sa, "k$i", "v$i";
    hm_si32_put $m_si32, "k$i", $i;
    hm_si_put $m_si, "k$i", $i;
    hm_ss_put $m_ss, "k$i", "v$i";
    $h_ii{$i} = $i;
    $h_ss{"k$i"} = "v$i";
}

print "\n", "-" x 70, "\n";
print "LOOKUP $N entries (all hits)\n";
print "-" x 70, "\n";
cmpthese(-3, {
    'I16' => sub {
        for my $i (1 .. $N16) { my $v = hm_i16_get $m_i16, $i; }
    },
    'I16A' => sub {
        for my $i (1 .. $N16) { my $v = hm_i16a_get $m_i16a, $i; }
    },
    'I16S' => sub {
        for my $i (1 .. $N16) { my $v = hm_i16s_get $m_i16s, $i; }
    },
    'SI16' => sub {
        for my $i (1 .. $N16) { my $v = hm_si16_get $m_si16, "k$i"; }
    },
    'I32' => sub {
        for my $i (1 .. $N) { my $v = hm_i32_get $m_i32, $i; }
    },
    'II' => sub {
        for my $i (1 .. $N) { my $v = hm_ii_get $m_ii, $i; }
    },
    'I32A' => sub {
        for my $i (1 .. $N) { my $v = hm_i32a_get $m_i32a, $i; }
    },
    'I32S' => sub {
        for my $i (1 .. $N) { my $v = hm_i32s_get $m_i32s, $i; }
    },
    'IA' => sub {
        for my $i (1 .. $N) { my $v = hm_ia_get $m_ia, $i; }
    },
    'IS' => sub {
        for my $i (1 .. $N) { my $v = hm_is_get $m_is, $i; }
    },
    'SA' => sub {
        for my $i (1 .. $N) { my $v = hm_sa_get $m_sa, "k$i"; }
    },
    'SI32' => sub {
        for my $i (1 .. $N) { my $v = hm_si32_get $m_si32, "k$i"; }
    },
    'SI' => sub {
        for my $i (1 .. $N) { my $v = hm_si_get $m_si, "k$i"; }
    },
    'SS' => sub {
        for my $i (1 .. $N) { my $v = hm_ss_get $m_ss, "k$i"; }
    },
    'perl_ii' => sub {
        for my $i (1 .. $N) { my $v = $h_ii{$i}; }
    },
    'perl_ss' => sub {
        for my $i (1 .. $N) { my $v = $h_ss{"k$i"}; }
    },
});

print "\n", "-" x 70, "\n";
print "INSERT $N entries (LRU / LRU+TTL overhead, II variant)\n";
print "-" x 70, "\n";
cmpthese(-3, {
    'II' => sub {
        my $m = Data::HashMap::II->new();
        for my $i (1 .. $N) { hm_ii_put $m, $i, $i; }
    },
    'II_lru' => sub {
        my $m = Data::HashMap::II->new($N);
        for my $i (1 .. $N) { hm_ii_put $m, $i, $i; }
    },
    'II_lru_ttl' => sub {
        my $m = Data::HashMap::II->new($N, 3600);
        for my $i (1 .. $N) { hm_ii_put $m, $i, $i; }
    },
});

# Pre-fill LRU maps for lookup benchmarks
my $m_ii_lru = Data::HashMap::II->new($N);
my $m_ii_lru_ttl = Data::HashMap::II->new($N, 3600);
for my $i (1 .. $N) {
    hm_ii_put $m_ii_lru, $i, $i;
    hm_ii_put $m_ii_lru_ttl, $i, $i;
}

print "\n", "-" x 70, "\n";
print "LOOKUP $N entries (LRU / LRU+TTL overhead, II variant)\n";
print "-" x 70, "\n";
cmpthese(-3, {
    'II' => sub {
        for my $i (1 .. $N) { my $v = hm_ii_get $m_ii, $i; }
    },
    'II_lru' => sub {
        for my $i (1 .. $N) { my $v = hm_ii_get $m_ii_lru, $i; }
    },
    'II_lru_ttl' => sub {
        for my $i (1 .. $N) { my $v = hm_ii_get $m_ii_lru_ttl, $i; }
    },
});

print "\n", "-" x 70, "\n";
print "LRU EVICTION CHURN: insert $N entries into capacity ${\int($N/2)} (II variant)\n";
print "-" x 70, "\n";
{
    my $cap = int($N / 2);
    cmpthese(-3, {
        'II_lru' => sub {
            my $m = Data::HashMap::II->new($cap);
            for my $i (1 .. $N) { hm_ii_put $m, $i, $i; }
        },
        'II_lru_ttl' => sub {
            my $m = Data::HashMap::II->new($cap, 3600);
            for my $i (1 .. $N) { hm_ii_put $m, $i, $i; }
        },
    });
}

print "\n", "-" x 70, "\n";
print "METHOD vs KEYWORD overhead ($N lookups, II variant)\n";
print "-" x 70, "\n";
cmpthese(-3, {
    'keyword' => sub {
        for my $i (1 .. $N) { my $v = hm_ii_get $m_ii, $i; }
    },
    'method' => sub {
        for my $i (1 .. $N) { my $v = $m_ii->get($i); }
    },
});

print "\n", "-" x 70, "\n";
print "METHOD vs KEYWORD overhead ($N inserts, II variant)\n";
print "-" x 70, "\n";
cmpthese(-3, {
    'keyword' => sub {
        my $m = Data::HashMap::II->new();
        for my $i (1 .. $N) { hm_ii_put $m, $i, $i; }
    },
    'method' => sub {
        my $m = Data::HashMap::II->new();
        for my $i (1 .. $N) { $m->put($i, $i); }
    },
});

print "\n", "-" x 70, "\n";
print "INCREMENT $N counters (int-value variants only)\n";
print "-" x 70, "\n";
cmpthese(-3, {
    'I16' => sub {
        my $m = Data::HashMap::I16->new();
        for my $i (1 .. $N16) { hm_i16_incr $m, $i; }
    },
    'I32' => sub {
        my $m = Data::HashMap::I32->new();
        for my $i (1 .. $N) { hm_i32_incr $m, $i; }
    },
    'II' => sub {
        my $m = Data::HashMap::II->new();
        for my $i (1 .. $N) { hm_ii_incr $m, $i; }
    },
    'SI16' => sub {
        my $m = Data::HashMap::SI16->new();
        for my $i (1 .. $N16) { hm_si16_incr $m, "k$i"; }
    },
    'SI32' => sub {
        my $m = Data::HashMap::SI32->new();
        for my $i (1 .. $N) { hm_si32_incr $m, "k$i"; }
    },
    'SI' => sub {
        my $m = Data::HashMap::SI->new();
        for my $i (1 .. $N) { hm_si_incr $m, "k$i"; }
    },
    'perl_ii' => sub {
        my %h;
        for my $i (1 .. $N) { $h{$i}++; }
    },
    'perl_ss' => sub {
        my %h;
        for my $i (1 .. $N) { $h{"k$i"}++; }
    },
});

print "\n", "-" x 70, "\n";
print "DELETE $N entries\n";
print "-" x 70, "\n";
cmpthese(-3, {
    'I16' => sub {
        my $m = Data::HashMap::I16->new();
        for my $i (1 .. $N16) { hm_i16_put $m, $i, $i; }
        for my $i (1 .. $N16) { hm_i16_remove $m, $i; }
    },
    'I16A' => sub {
        my $m = Data::HashMap::I16A->new();
        for my $i (1 .. $N16) { hm_i16a_put $m, $i, "v$i"; }
        for my $i (1 .. $N16) { hm_i16a_remove $m, $i; }
    },
    'I16S' => sub {
        my $m = Data::HashMap::I16S->new();
        for my $i (1 .. $N16) { hm_i16s_put $m, $i, "v$i"; }
        for my $i (1 .. $N16) { hm_i16s_remove $m, $i; }
    },
    'SI16' => sub {
        my $m = Data::HashMap::SI16->new();
        for my $i (1 .. $N16) { hm_si16_put $m, "k$i", $i; }
        for my $i (1 .. $N16) { hm_si16_remove $m, "k$i"; }
    },
    'I32' => sub {
        my $m = Data::HashMap::I32->new();
        for my $i (1 .. $N) { hm_i32_put $m, $i, $i; }
        for my $i (1 .. $N) { hm_i32_remove $m, $i; }
    },
    'II' => sub {
        my $m = Data::HashMap::II->new();
        for my $i (1 .. $N) { hm_ii_put $m, $i, $i; }
        for my $i (1 .. $N) { hm_ii_remove $m, $i; }
    },
    'I32A' => sub {
        my $m = Data::HashMap::I32A->new();
        for my $i (1 .. $N) { hm_i32a_put $m, $i, "v$i"; }
        for my $i (1 .. $N) { hm_i32a_remove $m, $i; }
    },
    'I32S' => sub {
        my $m = Data::HashMap::I32S->new();
        for my $i (1 .. $N) { hm_i32s_put $m, $i, "v$i"; }
        for my $i (1 .. $N) { hm_i32s_remove $m, $i; }
    },
    'IA' => sub {
        my $m = Data::HashMap::IA->new();
        for my $i (1 .. $N) { hm_ia_put $m, $i, "v$i"; }
        for my $i (1 .. $N) { hm_ia_remove $m, $i; }
    },
    'SA' => sub {
        my $m = Data::HashMap::SA->new();
        for my $i (1 .. $N) { hm_sa_put $m, "k$i", "v$i"; }
        for my $i (1 .. $N) { hm_sa_remove $m, "k$i"; }
    },
    'SI32' => sub {
        my $m = Data::HashMap::SI32->new();
        for my $i (1 .. $N) { hm_si32_put $m, "k$i", $i; }
        for my $i (1 .. $N) { hm_si32_remove $m, "k$i"; }
    },
    'IS' => sub {
        my $m = Data::HashMap::IS->new();
        for my $i (1 .. $N) { hm_is_put $m, $i, "v$i"; }
        for my $i (1 .. $N) { hm_is_remove $m, $i; }
    },
    'SI' => sub {
        my $m = Data::HashMap::SI->new();
        for my $i (1 .. $N) { hm_si_put $m, "k$i", $i; }
        for my $i (1 .. $N) { hm_si_remove $m, "k$i"; }
    },
    'SS' => sub {
        my $m = Data::HashMap::SS->new();
        for my $i (1 .. $N) { hm_ss_put $m, "k$i", "v$i"; }
        for my $i (1 .. $N) { hm_ss_remove $m, "k$i"; }
    },
    'perl_ii' => sub {
        my %h;
        for my $i (1 .. $N) { $h{$i} = $i; }
        for my $i (1 .. $N) { delete $h{$i}; }
    },
    'perl_ss' => sub {
        my %h;
        for my $i (1 .. $N) { $h{"k$i"} = "v$i"; }
        for my $i (1 .. $N) { delete $h{"k$i"}; }
    },
});

# --- Memory benchmarks ---

print "\n", "=" x 70, "\n";
print "MEMORY: $MEM_N entries (bytes per entry)\n";
print "=" x 70, "\n\n";

sub mem_rss_kb {
    my ($pid) = @_;
    $pid //= $$;
    if ($^O eq 'linux') {
        open my $fh, '<', "/proc/$pid/statm" or return 0;
        my $line = <$fh>;
        close $fh;
        my @fields = split /\s+/, $line;
        return $fields[1] * 4; # pages to KB (4K pages)
    }
    # macOS/FreeBSD: use ps
    my $out = `ps -o rss= -p $pid` // '';
    chomp $out;
    return ($out =~ /^(\d+)$/) ? $1 : 0;
}

sub measure_memory {
    my ($label, $setup, $n) = @_;
    $n //= $MEM_N;

    pipe(my $rd, my $wr) or die "pipe: $!";
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        close $rd;
        my $before = mem_rss_kb();
        my $obj = $setup->();
        my $after = mem_rss_kb();
        print $wr "$after $before\n";
        close $wr;
        POSIX::_exit(0);
    }
    close $wr;
    my $line = <$rd>;
    close $rd;
    waitpid($pid, 0);
    chomp $line;
    my ($after, $before) = split /\s+/, $line;
    my $delta_kb = $after - $before;
    my $bytes_per_entry = ($delta_kb * 1024) / $n;

    printf "  %-14s  %8d KB  (%5.1f bytes/entry)%s\n",
        $label, $delta_kb, $bytes_per_entry,
        ($n != $MEM_N ? "  [N=$n]" : "");
}

measure_memory('I16', sub {
    my $m = Data::HashMap::I16->new();
    for my $i (1 .. $MEM_N16) { hm_i16_put $m, $i, $i; }
    $m;
}, $MEM_N16);

measure_memory('I16A', sub {
    my $m = Data::HashMap::I16A->new();
    for my $i (1 .. $MEM_N16) { hm_i16a_put $m, $i, "v$i"; }
    $m;
}, $MEM_N16);

measure_memory('I16S', sub {
    my $m = Data::HashMap::I16S->new();
    for my $i (1 .. $MEM_N16) { hm_i16s_put $m, $i, "v$i"; }
    $m;
}, $MEM_N16);

measure_memory('I32', sub {
    my $m = Data::HashMap::I32->new();
    for my $i (1 .. $MEM_N) { hm_i32_put $m, $i, $i; }
    $m;
});

measure_memory('I32A', sub {
    my $m = Data::HashMap::I32A->new();
    for my $i (1 .. $MEM_N) { hm_i32a_put $m, $i, "v$i"; }
    $m;
});

measure_memory('II', sub {
    my $m = Data::HashMap::II->new();
    for my $i (1 .. $MEM_N) { hm_ii_put $m, $i, $i; }
    $m;
});

measure_memory('II_lru', sub {
    my $m = Data::HashMap::II->new($MEM_N);
    for my $i (1 .. $MEM_N) { hm_ii_put $m, $i, $i; }
    $m;
});

measure_memory('II_lru_ttl', sub {
    my $m = Data::HashMap::II->new($MEM_N, 3600);
    for my $i (1 .. $MEM_N) { hm_ii_put $m, $i, $i; }
    $m;
});

measure_memory('I32S', sub {
    my $m = Data::HashMap::I32S->new();
    for my $i (1 .. $MEM_N) { hm_i32s_put $m, $i, "v$i"; }
    $m;
});

measure_memory('IA', sub {
    my $m = Data::HashMap::IA->new();
    for my $i (1 .. $MEM_N) { hm_ia_put $m, $i, "v$i"; }
    $m;
});

measure_memory('IS', sub {
    my $m = Data::HashMap::IS->new();
    for my $i (1 .. $MEM_N) { hm_is_put $m, $i, "v$i"; }
    $m;
});

measure_memory('SA', sub {
    my $m = Data::HashMap::SA->new();
    for my $i (1 .. $MEM_N) { hm_sa_put $m, "k$i", "v$i"; }
    $m;
});

measure_memory('SI16', sub {
    my $m = Data::HashMap::SI16->new();
    for my $i (1 .. $MEM_N) { hm_si16_put $m, "k$i", 1; }
    $m;
});

measure_memory('SI32', sub {
    my $m = Data::HashMap::SI32->new();
    for my $i (1 .. $MEM_N) { hm_si32_put $m, "k$i", $i; }
    $m;
});

measure_memory('SI', sub {
    my $m = Data::HashMap::SI->new();
    for my $i (1 .. $MEM_N) { hm_si_put $m, "k$i", $i; }
    $m;
});

measure_memory('SS', sub {
    my $m = Data::HashMap::SS->new();
    for my $i (1 .. $MEM_N) { hm_ss_put $m, "k$i", "v$i"; }
    $m;
});

# SS with fixed-size strings: plain vs LRU vs LRU+TTL
for my $slen (8, 16, 32, 64) {
    my $key = "k" . ("x" x ($slen - 1));
    my $val = "v" . ("y" x ($slen - 1));
    my $tag = "SS_${slen}B";

    measure_memory($tag, sub {
        my $m = Data::HashMap::SS->new();
        for my $i (1 .. $MEM_N) { hm_ss_put $m, "$key$i", "$val$i"; }
        $m;
    });
    measure_memory("${tag}_lru", sub {
        my $m = Data::HashMap::SS->new($MEM_N);
        for my $i (1 .. $MEM_N) { hm_ss_put $m, "$key$i", "$val$i"; }
        $m;
    });
    measure_memory("${tag}_lttl", sub {
        my $m = Data::HashMap::SS->new($MEM_N, 3600);
        for my $i (1 .. $MEM_N) { hm_ss_put $m, "$key$i", "$val$i"; }
        $m;
    });
}

measure_memory('perl_ii', sub {
    my %h;
    for my $i (1 .. $MEM_N) { $h{$i} = $i; }
    \%h;
});

measure_memory('perl_ss', sub {
    my %h;
    for my $i (1 .. $MEM_N) { $h{"k$i"} = "v$i"; }
    \%h;
});

print "\nDone.\n";
