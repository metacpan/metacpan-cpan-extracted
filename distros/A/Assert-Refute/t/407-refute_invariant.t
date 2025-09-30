#!perl

use strict;
use warnings;
BEGIN { undef @ENV{ qw{NDEBUG PERL_NDEBUG} } };
use Test::More;

use Assert::Refute::T::Errors qw(dies_like);

dies_like {
    package T;
    use Assert::Refute qw(refute_invariant);
    refute_invariant '' => sub {};
} qr(Usage: refute_invariant), "no empty name";

dies_like {
    package T;
    use Assert::Refute qw(refute_invariant);
    refute_invariant 'good name' => {};
} qr(Usage: refute_invariant), "no empty coderef";

done_testing;

