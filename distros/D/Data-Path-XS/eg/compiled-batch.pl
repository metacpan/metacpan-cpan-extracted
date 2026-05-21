#!/usr/bin/env perl
# Demonstrate compiled-path ROI when the same path is reused many times.
#
# We simulate processing N records, each with K paths to extract. The
# compiled API parses each path once at startup; the string API parses
# it every call. Both produce identical output.
#
# Where compiled wins biggest: deep paths and missing-key probes
# (early termination on a pre-computed component). Very shallow paths
# may not benefit much because the indirection through the compiled
# object eats the parse savings.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Data::Path::XS qw(path_get path_compile pathc_get);

my $N = 5000;       # records
my @paths = qw(
    /id
    /user/name
    /user/addr/city
    /events/0/type
    /events/-1/timestamp
);

# Build a synthetic dataset of N records.
my @records;
for my $i (1 .. $N) {
    push @records, {
        id   => $i,
        user => { name => "user_$i", addr => { city => 'NYC', zip => '10001' } },
        events => [
            { type => 'login',  timestamp => 100_000 + $i },
            { type => 'logout', timestamp => 200_000 + $i },
        ],
    };
}

# Pre-compile once.
my @cps = map { path_compile($_) } @paths;

# Sanity: both forms produce identical output for record 0.
for my $i (0 .. $#paths) {
    my $a = path_get($records[0], $paths[$i]);
    my $b = pathc_get($records[0], $cps[$i]);
    no warnings 'uninitialized';
    $a eq $b or die "mismatch on $paths[$i]: '$a' vs '$b'";
}
print "sanity: $N records, ", scalar(@paths), " paths each, both forms agree\n\n";

print "Throughput (full pass over $N records, all ", scalar(@paths), " paths):\n";
cmpthese(-2, {
    'string API'   => sub {
        for my $r (@records) {
            for my $p (@paths) {
                my $v = path_get($r, $p);
            }
        }
    },
    'compiled API' => sub {
        for my $r (@records) {
            for my $cp (@cps) {
                my $v = pathc_get($r, $cp);
            }
        }
    },
});
