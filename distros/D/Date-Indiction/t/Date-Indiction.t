# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Indiction.t'

#########################

use Test::More;
use B qw(svref_2object);

use_ok('Date::Indiction');

sub sub_name {
	svref_2object(shift)->GV->NAME;
}

is (sub_name($Date::Indiction::SUB), 'byzantine', 'Default method is byzantine');

is (indiction(5508), 3, "indiction(5508) is 3");
is (indiction(5508, 12), 4, "indiction(Dec 5508) is 4");
is (indiction(5715), 15, "indiction(5715) is 15");
is (indiction(5715, 12), 1, "indiction(Dec 5715) is 1");
is (indiction(5715, 1), 1, "indiction(Jan 5715) is 1");

Date::Indiction::set_aera('AD');
is (sub_name($Date::Indiction::SUB), 'christian', 'Now method is AD=christian');

is (indiction(1986), 9, "indiction(1986 AD) is 9");
is (indiction(1986, 12), 10, "indiction(Dec 1986 AD) is 10");
is (indiction(2007), 15, "indiction(2007 AD) is 15");
is (indiction(2007, 12), 1, "indiction(Dec 2007 AD) is 1");

done_testing();