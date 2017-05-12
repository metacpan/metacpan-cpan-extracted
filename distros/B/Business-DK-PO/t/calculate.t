# $Id: calculate.t,v 1.2 2006-02-20 21:43:11 jonasbn Exp $

use strict;
use Test::More tests => 32;
use Test::Exception;

#Test 1, load test
BEGIN { use_ok('Business::DK::PO', qw(calculate validate)) };

#Test 2
dies_ok{calculate()} 'no arguments';

#Test 3
dies_ok{calculate(12345678901234567890)} 'too long';

#Test 4
dies_ok{validate("abcdefg123456789")} 'unclean';

#Test 5
dies_ok{validate(0)} 'zero';

#Test 6-7
ok(my $paymentid = calculate(123456389123456));
ok(validate($paymentid));

#Tests 8 ... 29
for (1 .. 10, 999999999999999) {
	ok(my $paymentid = calculate($_));
	ok(validate($paymentid));
}

ok(calculate(1234, 10), 'Coverage test, with maxlength argument');

ok(calculate(1234, 10, 4), 'Coverage test, with minlength argument');

ok(calculate(1234, undef, 4), 'Coverage test, with minlength argument, but not maxlength');
