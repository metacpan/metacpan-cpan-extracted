use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/lib'; use MyTest;

tzset('Europe/Moscow');
my $a = date("2017-08-28T13:49:35+01:00");
ok(!$a->error);
cmp_deeply([$a->year, $a->month, $a->day, $a->hour, $a->minute, $a->second], [2017, 8, 28, 13, 49, 35]);
is($a->epoch, 1503924575);
is($a->tzabbr, "+01:00");

$a = date("2017-02-99");
ok(!$a->error);

$a = date("2017-14-99");
ok(!$a->error);


$a = date("2017-08-28T13:49:35+0100");
is($a->epoch, 1503924575);
is($a->tzabbr, "+01:00");

$a = date("2017-08-28T13:49:35Z");
ok(!$a->error);
cmp_deeply([$a->year, $a->month, $a->day, $a->hour, $a->minute, $a->second], [2017, 8, 28, 13, 49, 35]);
is($a->epoch, 1503928175);
is($a->tzabbr, "GMT");

$a = date("2017-02");
ok(!$a->error);
cmp_deeply([$a->year, $a->month], [2017, 2]);
is($a->tzabbr, "MSK");

$a = date("2017-01-02T03:04:05");
ok(!$a->error);
cmp_deeply([$a->year, $a->month, $a->day, $a->hour, $a->minute, $a->second], [2017, 1, 2, 3, 4, 5]);
is($a->epoch, 1483315445);

$a = date("20170828T134935Z");
ok(!$a->error);
cmp_deeply([$a->year, $a->month, $a->day, $a->hour, $a->minute, $a->second], [2017, 8, 28, 13, 49, 35]);
is($a->epoch, 1503928175);

$a = date("2017-W06");
ok(!$a->error);
cmp_deeply([$a->year, $a->month, $a->day], [2017, 2, 6]);

$a = date("2014-W06");
ok(!$a->error);
cmp_deeply([$a->year, $a->month, $a->day], [2014, 2, 3]);

$a = date("2017-W35-3");
ok(!$a->error);
cmp_deeply([$a->year, $a->month, $a->day], [2017, 8, 30]);

$a = date("2014-W45-5");
ok(!$a->error);
cmp_deeply([$a->year, $a->month, $a->day], [2014, 11, 7]);

$a = date("2017-W01");
ok(!$a->error);
cmp_deeply([$a->year, $a->month, $a->day], [2017, 1, 2]);

$a = date("2017-W01-5");
ok(!$a->error);
cmp_deeply([$a->year, $a->month, $a->day], [2017, 1, 6]);

$a = date("2014-W01");
ok($a->error);

$a = date("2014-W01-2");
ok($a->error);

$a = date("cannotbeparsed");
ok($a->error);

done_testing();
