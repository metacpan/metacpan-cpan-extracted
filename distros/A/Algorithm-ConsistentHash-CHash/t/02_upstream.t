#!perl
use strict;
use warnings;
use Test::More;
use Algorithm::ConsistentHash::CHash;

my $expected = {
    "server1" => 19236,
    "server2" => 21802,
    "server3" => 21468,
    "server4" => 17602,
    "server5" => 19892,
};

my $actual = {};

my $ch = Algorithm::ConsistentHash::CHash->new(
    ids      => [ sort keys %$expected ],
    replicas => 160,
);

for ( my $i = 0 ; $i < 100000 ; $i++ ) {
    my $where = $ch->lookup("foo$i\n");
    $actual->{$where}++;
}

foreach my $node ( sort keys %$expected ) {
    is( $actual->{$node}, $expected->{$node}, "$node" );
}

pass("Alive");
done_testing();
