#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

BEGIN {
    use_ok('Class::Throwable' => qw(
                Exception::Test 
                Exception::Test::IllegalOperation
                ));
}

can_ok("Exception::Test", 'throw');
can_ok("Exception::Test::IllegalOperation", 'throw');

eval { throw Exception::Test };
isa_ok($@, 'Exception::Test');

is($@->getMessage(), 
   'An Exception::Test Exception has been thrown', 
   '... the custom message is correct');

eval { throw Exception::Test::IllegalOperation };
isa_ok($@, 'Exception::Test::IllegalOperation');

is($@->getMessage(), 
   'An Exception::Test::IllegalOperation Exception has been thrown', 
   '... the custom message is correct');