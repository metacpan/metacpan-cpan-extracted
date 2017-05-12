# $Id$

use strict;
use warnings;
use Test::More tests => 9;
use Test::Exception;

#Test 1
use_ok('Business::DK::FI', qw(validate validateFI));

#Test 2
ok(validate('026840149965328'), 'Ok');

#Test 3
dies_ok {validate()} 'no arguments';

#Test 4
dies_ok {validate(12345678901234)} 'too short, 14';

#Test 5
dies_ok {validate(1234567890123456)} 'too long, 16';

#Test 6
dies_ok {validate('0268401A9965328')} 'unclean';

#Test 7
dies_ok {validate(0)} 'zero';

#Test 8
ok(! validate('026840149965327'), 'error prone');

#Test 2
ok(validateFI('026840149965328'), 'Ok');
