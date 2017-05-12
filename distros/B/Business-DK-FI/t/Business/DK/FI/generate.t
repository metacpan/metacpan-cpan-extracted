# $Id$

use strict;
use warnings;
use Test::More tests => 8;
use Test::Exception;

#Test 1
use_ok('Business::DK::FI', qw(generate validate));

#Test 2
ok(validate(generate(1)), 'Ok');

ok(validate(generate(12345678901234)), 'Ok');

ok(validate(generate(99999999999999)), 'Ok');

dies_ok { validate(generate(-1)) } 'Invalid value';

dies_ok { validate(generate(0)) } 'too long, 15'; 

dies_ok { validate(generate(123456789012345)) } 'too long, 15'; 
         
dies_ok { generate() } 'no params';