#!perl
# Confold wraps PL_infix_plugin, which is a single global hook that other
# modules also chain onto. Anything Confold declines has to reach the plugin
# installed before it.
use 5.038;
use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => 'Infix::Custom required for the coexistence test'
        unless eval { require Infix::Custom; 1 };
}

plan tests => 4;

use Confold;
use Infix::Custom op => '<@>', call => sub { "$_[0]|$_[1]" };

is( (<: 42), 42, 'Confold still works with another infix plugin loaded' );

is( ("a" <@> "b"), 'a|b', 'the other plugin still sees its own operator' );

{
    my $v = "x";
    is( (<: $v), 'x', 'the runtime path is unaffected' );
}

{
    # The sharp case: an infix operator whose glyph *starts with* `<:`. The
    # trap only fires where a term is expected, so in operator position this
    # has to reach its owner untouched.
    use Infix::Custom op => '<:>', call => sub { "$_[0]/$_[1]" };
    is( ("l" <:> "r"), 'l/r',
        'an infix glyph beginning with the trapped one reaches its owner' );
}
