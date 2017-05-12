use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

my $orig;
my $code = sub { die };

do {
    package Class;
    use Class::Method::Modifiers;

    sub method {}
    $orig = Class->can('method');

    before method => $code;
};


is_deeply(\%Class::Method::Modifiers::MODIFIER_CACHE, {
    Class => {
        method => {
            before  => [$code],
            after   => [],
            around  => [],
            orig    => $orig,
            wrapped => $orig,
        },
    },
});

my $code2 = sub { 1 + 1 };

do {
    package Child;
    BEGIN { our @ISA = 'Class' }
    use Class::Method::Modifiers;

    after method => $code2;
};

my $fake = $Class::Method::Modifiers::MODIFIER_CACHE{Child}{method}{wrapped};

is_deeply(\%Class::Method::Modifiers::MODIFIER_CACHE, {
    Class => {
        method => {
            before  => [$code],
            after   => [],
            around  => [],
            orig    => $orig,
            wrapped => $orig,
        },
    },
    Child => {
        method => {
            before  => [],
            after   => [$code2],
            around  => [],
            orig    => undef,
            wrapped => $fake,
        },
    },
});

my $around1 = sub { "around1" };
my $around2 = sub { "around2" };

do {
    package Class;
    use Class::Method::Modifiers;

    around method => $around1;
    around method => $around2;
};

# XXX: hard to test, we have no other way of getting at this coderef
my $wrapped  = $Class::Method::Modifiers::MODIFIER_CACHE{Class}{method}{wrapped};

is_deeply(\%Class::Method::Modifiers::MODIFIER_CACHE, {
    Class => {
        method => {
            around  => [$around2, $around1],
            before  => [$code],
            after   => [],
            orig    => $orig,
            wrapped => $wrapped,
        },
    },
    Child => {
        method => {
            before  => [],
            after   => [$code2],
            around  => [],
            orig    => undef,
            wrapped => $fake,
        },
    },
});

done_testing;
