use strict;
use warnings;
use Test::More;

plan tests => 18;

use Class::Date qw(:errors gmdate);

$Class::Date::DST_ADJUST=1;

ok(1);

my $t = gmdate("195xwerf9");
ok !$t;
is $t->error, E_UNPARSABLE;
is $t->errstr, "Unparsable date or time: 195xwerf9\n";

$Class::Date::RANGE_CHECK=0;

$t = gmdate("2001-02-31");
is $t, "2001-03-03";

$Class::Date::RANGE_CHECK=1;

$t = gmdate("2001-02-31");
ok !$t;
ok $t ? 0 : 1;
is $t->error, E_RANGE;
is $t->errstr, "Range check on date or time failed\n";

$t = gmdate("2006-2-6")->clone( month => -1);
ok !$t;
ok $t ? 0 : 1;

$t = new Class::Date(undef);
ok ! $t;
ok $t ? 0 : 1;
is $t->error, E_UNDEFINED;
is $t->errstr, "Undefined date object\n";

$t = gmdate("2006-2-6")->clone(month => 16);
ok !$t;
ok $t ? 0 : 1;

$t = gmdate("2001-05-04 07:09:09") + [1,-2,-4];
ok $t;
