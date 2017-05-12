#! perl -T

use Test::More tests => 14;

use Business::SWIFT;

ok( Business::SWIFT->validateBIC('DEUTDEFF' ) , 'DEUTDEFF valid');
ok( Business::SWIFT->validateBIC('DEUTDEFFXXX' ) , 'DEUTDEFFXXX valid');
ok( Business::SWIFT->validateBIC('DEUTGBFFA23' ) , 'DEUTGBFFA23 valid');
ok( Business::SWIFT->validateBIC('DEUTDEFF500' ) , 'DEUTDEFF500 valid');
ok( Business::SWIFT->validateBIC(uc('UKCBUau102v')) , 'UKCBUau102v valid');
ok( Business::SWIFT->validateBIC('UKIOLT2XXXX') , 'UKIOLT2XXXX valid');
ok( Business::SWIFT->validateBIC('GBMCMRMRXXX') , 'GBMCMRMRXXX valid');
ok( Business::SWIFT->validateBIC('GBTXUS31XXX') , 'GBTXUS31XXX valid');
ok( Business::SWIFT->validateBIC('JUBIGB21XXX') , 'JUBIGB21XXX valid');

ok( ! Business::SWIFT->validateBIC('DEUTDEF' ) , 'not valid length');
ok( ! Business::SWIFT->validateBIC('DEUTJUFFA23') , 'not valid country JU');
ok( ! Business::SWIFT->validateBIC('DE1TGBFFA23' ) , 'not valid number');
ok( ! Business::SWIFT->validateBIC('DEUTGB_2A23' ) , 'not valid loc code');
ok( ! Business::SWIFT->validateBIC('DEUTDEFF5=0' ) , 'not valid branch code');
