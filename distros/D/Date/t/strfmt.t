use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

my $date = Date->new("2013-03-05 02:04:06");
is($date, "2013-03-05 02:04:06");
is($date->to_string, $date);
is($date, $date->sql);
is($date->iso, $date->sql);
ok(!defined Date::string_format);
Date::string_format("%Y%m%d%H%M%S");
is(Date::string_format, "%Y%m%d%H%M%S");
is($date->to_string, "20130305020406");
Date::string_format("%Y/%m/%d");
is($date->to_string, "2013/03/05");
Date::string_format(undef);
is($date->to_string, "2013-03-05 02:04:06");

done_testing();
