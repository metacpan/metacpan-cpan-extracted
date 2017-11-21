use strict;
use warnings;

use Test::More;
use App::EvalServerAdvanced::ConstantCalc;

my $calc = App::EvalServerAdvanced::ConstantCalc->new();

ok($calc->add_constant("foo", 0x01));
ok($calc->add_constant("bar", "0x02"));
ok($calc->add_constant("baz", "9"));

is($calc->calculate("foo|bar"), 3);

is($calc->calculate("1|2&4"), 1|2&4); # check precedence
is($calc->calculate("(1|2)&4"), (1|2)&4);
is($calc->calculate("3&2&1"), 3&2&1);
is($calc->calculate("3&2^1"), 3&2^1);
is($calc->calculate("(1|2^4)&7^~[16]1"), 65529);

is($calc->calculate("~[32]((0xF000|0b1000)^0o777)"), 4294905352);

done_testing;
