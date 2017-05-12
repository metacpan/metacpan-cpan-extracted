# $Id$

use strict;
use Test::More tests => 8;
use Test::Exception;

#Test 1
BEGIN { use_ok('Business::DK::CVR', qw(validateCVR)) };

#Test 2
ok(validateCVR(27355021), 'Ok');

#Test 3
dies_ok {validateCVR()} 'no arguments';

#Test 4
dies_ok {validateCVR(1234567)} 'too short, 7';

#Test 5
dies_ok {validateCVR(123456789)} 'too long, 9';

#Test 6
dies_ok {validateCVR("abcdefg1")} 'unclean';

#Test 7
dies_ok {validateCVR(0)} 'zero';

#Test 8
ok(! validateCVR("00000050"), 'error prone');
