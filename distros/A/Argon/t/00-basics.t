use strict;
use warnings;
use Test::More;

use_ok('Argon') or BAIL_OUT;

# K
{
    package Foo;
    sub new { bless [undef, undef], shift }
    sub bar {
        $_[0]->[0] = $_[1];
        $_[0]->[1] = $_[2];
        return 1;
    }

    package main;
    my $ctx = Foo->new;
    my $k   = Argon::K('bar', $ctx, 4);

    is(ref $k, 'CODE', 'K returns code ref') or BAIL_OUT;
    ok($k->(2), 'K gets intended result');
    is($ctx->[0], 4, 'K passes curried args');
    is($ctx->[1], 2, 'K passed args correctly');
}

done_testing;
