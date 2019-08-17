use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

Date::string_format("%Y-%m-%d");

ok(!Date::range_check);
is(Date->new("2001-02-31"), "2001-03-03");

Date::range_check(1);
ok(Date::range_check);
my $date = Date->new("2001-02-31");
ok(!$date);
ok(!defined $date->string);
is(int($date), 0);
is($date->error, E_RANGE);
ok($date->errstr);

done_testing();
