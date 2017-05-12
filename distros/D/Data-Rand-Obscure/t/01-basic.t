#!perl -T

use Test::More qw/no_plan/;

use Data::Rand::Obscure;

my $random;
ok($random = Data::Rand::Obscure::create);
ok($random = Data::Rand::Obscure::create_hex);
ok($random = Data::Rand::Obscure::create_b64);
ok($random = Data::Rand::Obscure::create_bin);


# Naive check to see we don't get duplicates
ok($random = Data::Rand::Obscure::create_hex);
for (1 .. 20) {
    ok(my $different = Data::Rand::Obscure::create_hex);
    isnt($random, $different);
}

for my $length (8 .. 2 ** 8) {
    ok($random = Data::Rand::Obscure::create(length => $length)); is(length($random), $length);
    ok($random = Data::Rand::Obscure::create_hex(length => $length)); is(length($random), $length);
    ok($random = Data::Rand::Obscure::create_b64(length => $length)); is(length($random), $length);
    ok($random = Data::Rand::Obscure::create_bin(length => $length)); is(length($random), $length);
}
