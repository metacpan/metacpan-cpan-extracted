
use strict;
use Test::More tests => 823;
use Test::Exception;

#Test 1, load test
use_ok('Business::DK::CPR', qw(calculate validate1968));

#Test 2
dies_ok{calculate()} 'no arguments';

#Test 3
dies_ok{calculate(1501721)} 'too long';

#Test 6
is(calculate(150172), 818);

#Test 7
ok(my @cprs = calculate(150172));

foreach (@cprs) {
	ok(validate1968($_));
}
