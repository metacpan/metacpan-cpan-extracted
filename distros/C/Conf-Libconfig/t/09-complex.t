#!perl -T
use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 5;
use Test::Deep;

use Conf::Libconfig;

my $foo = Conf::Libconfig->new();

# test the generic add method

# single scalar at the top level
ok($foo->add('', s => 'aScalar'), "ok - scalar at top");
my $expected = { s => 'aScalar'};
TODO: {
   local $TODO = "get not implemented";
   #cmp_deeply($foo->get('s'), $expected);
}

# simple array at top level
$expected->{array} = [0..3];
ok($foo->add('', array => [0..3]), "ok - simple array at top");
TODO: {
   local $TODO = "get not implemented";
   #cmp_deeply($foo->get(''), $expected);
}


# simple hash
$expected->{hash} = { hash => 77 };
ok($foo->add('', hash => 77), "ok - simple hash at top");
TODO: {
   local $TODO = "get not implemented";
   #cmp_deeply($foo->get(''), $expected);
}

# nested hash-array-hash
my $c = { a => [ { b => 'c' } ], d => 'e' };
$expected->{complex} = $c;
ok($foo->add_hash('', 'c', {}), "ok - add hash key");
ok($foo->add('c', complex => $c), "ok - nested structure");
TODO: {
   local $TODO = "get not implemented";
   #cmp_deeply($foo->get('c'), $expected->{c});
}
