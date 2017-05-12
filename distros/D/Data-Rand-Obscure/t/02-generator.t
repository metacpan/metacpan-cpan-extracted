#!perl -T

use Test::More qw/no_plan/;

use Data::Rand::Obscure;

ok(my $generator = Data::Rand::Obscure->new);
is(ref $generator, qw/Data::Rand::Obscure::Generator/);

my $random;
ok($random = $generator->create);
ok($random = $generator->create_hex);
ok($random = $generator->create_b64);
ok($random = $generator->create_bin);


# Naive check to see we don't get duplicates
ok($random = $generator->create_hex);
for (1 .. 20) {
    ok(my $different = $generator->create_hex);
    isnt($random, $different);
}

for my $length (8 .. 2 ** 8) {
    ok($random = $generator->create(length => $length)); is(length($random), $length);
    ok($random = $generator->create_hex(length => $length)); is(length($random), $length);
    ok($random = $generator->create_b64(length => $length)); is(length($random), $length);
    ok($random = $generator->create_bin(length => $length)); is(length($random), $length);
}

$generator = Data::Rand::Obscure::Generator->new(seeder => sub { "Really lame seed" });
$random = $generator->create;
for (1 .. 10) {
    is($random, $generator->create); # Should be all the same 'cause we got a really lame seed.
}
