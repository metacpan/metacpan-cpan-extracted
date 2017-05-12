#!perl

use strict;
use Test::More;

# https://github.com/dgryski/go-ketama/commit/5fb0f7e85cb457c4cfb78bb892d02434d9f0620b

use Algorithm::ConsistentHash::Ketama;

# This is the old behavior
subtest 'Old behavior' => sub {
    my $ketama = Algorithm::ConsistentHash::Ketama->new();
    $ketama->add_bucket( "r01", 100 );
    $ketama->add_bucket( "r02", 100 );

    for my $v (qw(37292b669dd8f7c952cf79ca0dc6c5d7 161c6d14dae73a874ac0aa0017fb8340)) {
        my $key = $ketama->hash( pack "H*", $v );
        is $key, "r01", "old behavior: should be r01";
    }
};

# This is the new behavior
subtest 'New behavior' => sub {
    my $ketama = Algorithm::ConsistentHash::Ketama->new(
        use_hashfunc => Algorithm::ConsistentHash::Ketama::HASHFUNC2(),
    );
    $ketama->add_bucket( "r01", 100 );
    $ketama->add_bucket( "r02", 100 );

    for my $v (qw(37292b669dd8f7c952cf79ca0dc6c5d7 161c6d14dae73a874ac0aa0017fb8340)) {
        my $key = $ketama->hash( pack "H*", $v );
        is $key, "r02", "new behavior: should be r02";
    }
};

done_testing;
