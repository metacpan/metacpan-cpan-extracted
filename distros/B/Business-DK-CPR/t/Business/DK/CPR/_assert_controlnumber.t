
use strict;
use Test::More tests => 6;
use Test::Exception;

#Test 1, load test
use_ok('Business::DK::CPR');

#Test 2
ok(Business::DK::CPR::_assert_controlnumber(1234567890), 'Ok');

#Test 3
dies_ok{Business::DK::CPR::_assert_controlnumber()} 'none';

#Test 4
dies_ok{Business::DK::CPR::_assert_controlnumber("abc")} 'tainted';

#Test 5
dies_ok{Business::DK::CPR::_assert_controlnumber(123)} 'bad controlnumber';

#Test 5
dies_ok{Business::DK::CPR::_assert_controlnumber(12345678901)} 'bad controlnumber';
