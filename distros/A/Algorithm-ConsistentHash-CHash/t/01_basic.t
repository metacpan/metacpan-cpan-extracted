#!perl
use strict;
use warnings;
use Test::More;
use Algorithm::ConsistentHash::CHash;

my $ch = Algorithm::ConsistentHash::CHash->new(
  ids => [qw(node1 node2 node3)],
  replicas => 1000,
);

SCOPE: {
  my $where = $ch->lookup("123");
  ok(defined $where, "lookup output defined");
  ok($where eq 'node1' || $where eq 'node2' || $where eq 'node3',
     "lookup output is one of the valid values");
}

my %nodes;
for (1..10000) {
  my $where = $ch->lookup($_);
  $nodes{$where}++;
}

for (qw(node1 node2 node3)) {
  ok($nodes{$_} > 0, "have hits for node '$_'");
}
is($nodes{node1} + $nodes{node2} + $nodes{node3}, 10000,
   "Sum of lookups adds up (duh)");

pass("Alive");
done_testing();
