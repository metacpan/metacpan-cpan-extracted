
use strict;
use Test::More tests => 8;
use Test::Exception;

#Test 1
use_ok('Business::DK::CPR', qw(validate1968));

#Test 2
ok(validate1968(1501721111), 'Ok, generated');

#Test 3
dies_ok {validate1968()} 'no arguments';

#Test 4
dies_ok {validate1968(123456789)} 'too short, 9';

#Test 5
dies_ok {validate1968(12345678901)} 'too long, 11';

#Test 6
dies_ok {validate1968('abcdefg1')} 'unclean';

#Test 7
dies_ok {validate1968(0)} 'zero';

#Test 8
ok(! validate1968('1501729993'), 'invalid');
