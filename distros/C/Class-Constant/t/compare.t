#!perl -T

use Test::More tests => 9;

use Class::Constant ZERO, ONE, TWO;

ok(ZERO == ZERO);
ok(ONE  == ONE);
ok(TWO  == TWO);

ok(ZERO != ONE);
ok(ZERO != TWO);
ok(ONE  != ZERO);
ok(ONE  != TWO);
ok(TWO  != ZERO);
ok(TWO  != ONE);
