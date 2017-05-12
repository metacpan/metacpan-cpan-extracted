use utf8;
use strict;
use warnings;

use Test::More;
use DateTime::Format::JavaScript;

# Safari 7 / Chrome 36 / Firefox 30
my $dt = DateTime::Format::JavaScript->parse_datetime("Sat Jul 26 2014 16:37:29 GMT+0900 (JST)");
isa_ok($dt, 'DateTime');
is($dt->year, 2014);
is($dt->month, 7);
is($dt->day, 26);
is($dt->hour, 16);
is($dt->minute, 37);
is($dt->second, 29);

# Opera 9
$dt = DateTime::Format::JavaScript->parse_datetime("Sat, 26 Jul 2014 16:37:29 GMT+0900");
isa_ok($dt, 'DateTime');
is($dt->year, 2014);
is($dt->month, 7);
is($dt->day, 26);
is($dt->hour, 16);
is($dt->minute, 37);
is($dt->second, 29);

# IE11
$dt = DateTime::Format::JavaScript->parse_datetime("Sat Jan 6 2014 23:40:03 GMT+0900 (東京 (標準時))");
isa_ok($dt, 'DateTime');
is($dt->year, 2014);
is($dt->month, 1);
is($dt->day, 6);
is($dt->hour, 23);
is($dt->minute, 40);
is($dt->second, 3);

done_testing;
