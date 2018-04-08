#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");

use Scalar::Util qw(refaddr);
use Test::More;

BEGIN
{
    $ENV{CLONE_CHOOSE_PREFERRED_BACKEND} and eval "use $ENV{CLONE_CHOOSE_PREFERRED_BACKEND}; 1;";
    $@ and plan skip_all => "No $ENV{CLONE_CHOOSE_PREFERRED_BACKEND} found.";
}

use Clone::Choose;

my $hash = {
    level => 0,
    href  => {
        level => 1,
        href  => {
            level => 2,
            href  => {level => 3},
        },
    },
};
my $cloned_hash = clone $hash;

ok(refaddr $hash != refaddr $cloned_hash,                                                   "Clone depth 0");
ok(refaddr($hash->{href}) != refaddr($cloned_hash->{href}),                                 "Clone depth 1");
ok(refaddr($hash->{href}->{href}) != refaddr($cloned_hash->{href}->{href}),                 "Clone depth 2");
ok(refaddr($hash->{href}->{href}->{href}) != refaddr($cloned_hash->{href}->{href}->{href}), "Clone depth 3");

ok($hash->{level} == $cloned_hash->{level},                                                 "Hash value depth 0");
ok($hash->{href}->{level} == $cloned_hash->{href}->{level},                                 "Hash value depth 1");
ok($hash->{href}->{href}->{level} == $cloned_hash->{href}->{href}->{level},                 "Hash value depth 2");
ok($hash->{href}->{href}->{href}->{level} == $cloned_hash->{href}->{href}->{href}->{level}, "Hash value depth 3");

ok($hash->{level} == 0,                         "Hash value sanity depth 0");
ok($hash->{href}->{level} == 1,                 "Hash value sanity depth 1");
ok($hash->{href}->{href}->{level} == 2,         "Hash value sanity depth 2");
ok($hash->{href}->{href}->{href}->{level} == 3, "Hash value sanity depth 3");

my $empty_hash        = {};
my $cloned_empty_hash = clone $empty_hash;

ok(refaddr $empty_hash != refaddr $cloned_empty_hash, "Empty hash clone");

done_testing;


