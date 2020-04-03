use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

ok(!Date::range_check);
is(Date->new("2001-02-31"), "2001-03-03 00:00:00");

Date::range_check(1);
ok(Date::range_check);
my $date = Date->new("2001-02-31");
ok(!$date);
ok(!defined $date->to_string);
is(int($date), 0);
is($date->error, Date::Error::out_of_range);

done_testing();
