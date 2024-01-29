# Deterministic random test

use 5.010;
use strict;
use warnings;

use Data::Gimei;
use Test::More;

my @expected;
Data::Gimei::set_random_seed(42);
push @expected, Data::Gimei::Name->new();
push @expected, Data::Gimei::Name->new();
push @expected, Data::Gimei::Address->new();

# Same seed generates same result.
{
    my @actual;
    Data::Gimei::set_random_seed(42);
    push @actual, Data::Gimei::Name->new();
    push @actual, Data::Gimei::Name->new();
    push @actual, Data::Gimei::Address->new();

    is_deeply [ map { $_->kanji } @expected ], [ map { $_->kanji } @actual ];
}

# Different seed might generates different result.
{
    my @actual;
    Data::Gimei::set_random_seed(43);
    push @actual, Data::Gimei::Name->new();
    push @actual, Data::Gimei::Name->new();
    push @actual, Data::Gimei::Address->new();

    isnt $actual[0]->kanji, $expected[0]->kanji;
    isnt $actual[1]->kanji, $expected[1]->kanji;
    isnt $actual[2]->kanji, $expected[2]->kanji;
}

# SHOULD NOT depend on calling rand()
{
    my @actual;
    Data::Gimei::set_random_seed(42);
    rand;
    push @actual, Data::Gimei::Name->new();
    rand;
    push @actual, Data::Gimei::Name->new();
    rand;
    push @actual, Data::Gimei::Address->new();

    is_deeply [ map { $_->kanji } @expected ], [ map { $_->kanji } @actual ];
}

done_testing();
