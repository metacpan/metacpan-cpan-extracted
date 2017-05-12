# $Id: validate.t,v 1.1 2008-06-11 08:08:00 jonasbn Exp $

use strict;
use Test::More tests => 8;
use Test::Exception;

#Test 1
BEGIN { use_ok('Business::DK::CVR', qw(validate)) };

#Test 2
ok(validate(27355021), 'Ok');

#Test 3
dies_ok {validate()} 'no arguments';

#Test 4
dies_ok {validate(1234567)} 'too short, 7';

#Test 5
dies_ok {validate(123456789)} 'too long, 9';

#Test 6
dies_ok {validate("abcdefg1")} 'unclean';

#Test 7
dies_ok {validate(0)} 'zero';

#Test 8
ok(! validate("00000050"), 'error prone');
