#!/usr/bin/env perl
use strict;
use warnings;
use Data::RadixTree::Shared;

# A tiny longest-prefix routing demo. Store CIDR-like string prefixes -> a
# "next hop" id, then route a few addresses to the most specific prefix that
# covers them via longest_prefix(). (String prefixes, not real bitwise CIDR --
# the point is the longest-prefix-match operation a routing table performs.)

my $rt = Data::RadixTree::Shared->new(undef, 4096, 65536);

# prefix -> next-hop id
my %route = (
    "10."          => 1,   # everything in 10.x
    "10.0."        => 2,   # more specific: 10.0.x
    "10.0.0."      => 3,   # 10.0.0.x
    "192.168."     => 4,   # 192.168.x
    "192.168.1."   => 5,   # 192.168.1.x
    "172.16."      => 6,
);
my %hop_name = (1 => 'core', 2 => 'edge-a', 3 => 'rack-1', 4 => 'office', 5 => 'lab', 6 => 'dmz');

$rt->insert($_, $route{$_}) for sort keys %route;

# a default route: the empty prefix matches anything (lowest priority)
$rt->insert("", 0);
$hop_name{0} = 'default';

my @addrs = qw(
    10.0.0.7
    10.0.5.9
    10.9.9.9
    192.168.1.50
    192.168.4.4
    172.16.30.1
    8.8.8.8
);

printf "%-16s   %-12s\n", 'ADDRESS', 'NEXT HOP';
for my $ip (@addrs) {
    my $hop = $rt->longest_prefix($ip);     # value of the longest stored prefix of $ip
    $hop = 0 unless defined $hop;
    printf "%-16s   %-12s\n", $ip, $hop_name{$hop};
}

# exact-match lookups still work alongside the prefix routing
printf "\nexact lookup of the prefix '10.0.0.' -> hop %s (%s)\n",
    $rt->lookup("10.0.0."), $hop_name{ $rt->lookup("10.0.0.") };

my $st = $rt->stats;
printf "stored %d routes; nodes=%d/%d arena=%d/%d\n",
    $rt->count, $st->{nodes_used}, $st->{nodes_capacity},
    $st->{arena_used}, $st->{arena_capacity};
