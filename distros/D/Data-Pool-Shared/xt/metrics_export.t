use strict;
use warnings;
use Test::More;

# Metrics export round-trip: stats → JSON (or TAP-friendly format) →
# parse → invariants hold. Tests that documented stat fields are
# present, well-typed, and roundtrip cleanly.

BEGIN {
    eval { require JSON::PP; 1 }
        or plan skip_all => "JSON::PP not available";
}
use JSON::PP qw(encode_json decode_json);

use Data::Pool::Shared;

my $p = Data::Pool::Shared::I64->new_memfd("metrics", 16);
$p->alloc for 1..5;

my $stats = $p->stats;
isa_ok $stats, 'HASH', "stats is a hashref";

# Expected fields (at minimum). Modules may document more.
my @expected = qw(used capacity allocs frees waiters);
for my $k (@expected) {
    ok exists $stats->{$k}, "stats has '$k' field";
    ok defined $stats->{$k}, "stats '$k' is defined";
    ok $stats->{$k} =~ /^\d+$/, "stats '$k' is non-negative integer ($stats->{$k})";
}

# Serialize → parse
my $json = eval { encode_json($stats) };
ok !$@, "stats serializes to JSON: $@" if $@;
ok length($json) > 20, "non-trivial JSON: " . substr($json, 0, 80);

my $decoded = decode_json($json);
is_deeply $decoded, $stats, "JSON roundtrip preserves hash";

# Invariants
cmp_ok $stats->{used}, '<=', $stats->{capacity}, "used <= capacity";
cmp_ok $stats->{allocs}, '>=', $stats->{frees}, "allocs >= frees";
is $stats->{used}, $stats->{allocs} - $stats->{frees},
    "used = allocs - frees";

done_testing;
