#!/usr/bin/perl
use warnings;
use strict;
use lib qw(lib t);
use Benchmark;

{
    package Foo;
    use strict;
    use warnings;
    use lib qw(lib t ..);

    use Ambrosia::Utils::Enumeration property => __state => RUN => 1, DONE => 2;
    use Ambrosia::Utils::Enumeration flag => __options => F1 => 0, F2 => 1, F3 => 2;

    use Ambrosia::Meta;
    class
    {
        private => [qw/__state __options/],
    };

    1;
}

    my $foo = new Foo();

my $NUM_ITER = 250000;

timethese($NUM_ITER, {
    'setProperty'   => sub { $foo->SET_RUN() },
    'offProperty'   => sub { $foo->OFF_RUN() },
    'checkProperty' => sub { $foo->IS_RUN() },

    'onFlagg'   => sub { $foo->ON_F1() },
    'offFlagg'  => sub { $foo->OFF_F1() },
    'checkFlag' => sub { $foo->IS_F1() },
});
