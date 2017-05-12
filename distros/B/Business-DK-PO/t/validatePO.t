# $Id$

use strict;
use Test::More tests => 9;
use Test::Exception;

#Test 1, load test
BEGIN { use_ok('Business::DK::PO', qw(validatePO)) };

#Test 2
ok(validatePO("1234563891234562"), 'from example');

#Test 3
ok(validatePO("0000000000000018"), 'ok');

#Test 4
dies_ok {validatePO()} 'no arguments';

#Test 5
dies_ok {validatePO(123456789012345)} 'too short, 15';

#Test 6
dies_ok {validatePO(12345678901234567)} 'too long, 17';

#Test 7
dies_ok {validatePO("abcdefg123456789")} 'unclean';

#Test 8
dies_ok {validatePO(0)} 'zero';

#Test 9
ok(! validatePO("0000000000000050"), 'error prone');
