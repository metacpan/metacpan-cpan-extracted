#!/usr/bin/env perl
use strict;
use warnings;
use Data::HashMap::II;
use Data::HashMap::SS;
use Data::HashMap::SI;

# --- Integer -> Integer ---
my $scores = Data::HashMap::II->new();

hm_ii_put $scores, 1001, 95;
hm_ii_put $scores, 1002, 87;
hm_ii_put $scores, 1003, 92;

printf "Student 1001 score: %d\n", hm_ii_get $scores, 1001;
printf "Total students: %d\n", hm_ii_size $scores;

# Counter operations
my $hits = Data::HashMap::II->new();
hm_ii_incr $hits, 404;
hm_ii_incr $hits, 404;
hm_ii_incr $hits, 200;
hm_ii_incr_by $hits, 200, 10;
printf "404 count: %d, 200 count: %d\n", hm_ii_get $hits, 404, hm_ii_get $hits, 200;

# --- String -> String ---
my $config = Data::HashMap::SS->new();

hm_ss_put $config, "host", "localhost";
hm_ss_put $config, "port", "5432";
hm_ss_put $config, "db",   "myapp";

printf "Connect to %s:%s/%s\n",
    hm_ss_get $config, "host",
    hm_ss_get $config, "port",
    hm_ss_get $config, "db";

# Iteration
print "Config keys: ", join(", ", sort (hm_ss_keys $config)), "\n";

# --- String -> Integer (word frequency) ---
my $freq = Data::HashMap::SI->new();

my $text = "the quick brown fox jumps over the lazy dog the fox";
for my $word (split /\s+/, $text) {
    hm_si_incr $freq, $word;
}

my @items = hm_si_items $freq;
my %h = @items;
for my $word (sort { $h{$b} <=> $h{$a} } keys %h) {
    printf "  %-10s %d\n", $word, $h{$word};
}

# --- Method dispatch (same operations, OO style) ---
my $m = Data::HashMap::SI->new();
$m->put("apples", 3);
$m->incr("apples");
printf "Apples: %d\n", $m->get("apples");
