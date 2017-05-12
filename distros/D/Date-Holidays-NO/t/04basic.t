# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################


use Test::More;
BEGIN { plan tests => 3 };
use_ok( Date::Holidays::NO);

is(Date::Holidays::NO::is_holiday(2004,5,17),'grunnlovsdag');
is(${Date::Holidays::NO::holidays(2004)}{"0517"},'grunnlovsdag');

