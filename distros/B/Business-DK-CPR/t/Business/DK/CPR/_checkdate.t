
use strict;
use Test::More tests => 5;
use Test::Exception;

#Test 1, load test
BEGIN { use_ok('Business::DK::CPR'); };

#Test 2
ok(Business::DK::CPR::_checkdate(150172), 'Ok');

#Test 3
dies_ok{Business::DK::CPR::_checkdate()} 'none';

#Test 4
dies_ok{Business::DK::CPR::_checkdate("abc")} 'tainted';

#Test 5
dies_ok{Business::DK::CPR::_checkdate(310205)} 'bad date';
