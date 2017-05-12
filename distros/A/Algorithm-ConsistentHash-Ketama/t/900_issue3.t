use strict;
use Test::More;

use Algorithm::ConsistentHash::Ketama;

my $ketama = Algorithm::ConsistentHash::Ketama->new();
$ketama->add_bucket( "r01", 100 );
$ketama->add_bucket( "r02", 100 );
my $key = $ketama->hash( pack "H*", "161c6d14dae73a874ac0aa0017fb8340" );
ok $key;
my $key2 = $ketama->hash( pack "H*", "37292b669dd8f7c952cf79ca0dc6c5d7" );
ok $key2;

done_testing;