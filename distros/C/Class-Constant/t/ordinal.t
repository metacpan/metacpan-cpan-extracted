#!perl -T

use Test::More tests => 13;

use Class::Constant ZERO, ONE, TWO, THREE, FOUR, FIVE;

is(ZERO->get_ordinal,   0);
is(ONE->get_ordinal,    1);
is(TWO->get_ordinal,    2);
is(THREE->get_ordinal,  3);
is(FOUR->get_ordinal,   4);
is(FIVE->get_ordinal,   5);

ok(__PACKAGE__->by_ordinal(0) == ZERO);
ok(__PACKAGE__->by_ordinal(1) == ONE);
ok(__PACKAGE__->by_ordinal(2) == TWO);
ok(__PACKAGE__->by_ordinal(3) == THREE);
ok(__PACKAGE__->by_ordinal(4) == FOUR);
ok(__PACKAGE__->by_ordinal(5) == FIVE);

eval {
    __PACKAGE__->by_ordinal(6);
};
my $err = $@;
ok($err =~ /Can't locate constant with ordinal/);
