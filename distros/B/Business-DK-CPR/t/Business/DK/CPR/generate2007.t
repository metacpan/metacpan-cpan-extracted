
use strict;
use Test::More tests => 9994;
use Test::Exception;
        
#Test 1, load test
use_ok('Business::DK::CPR', qw(validate2007 generate2007));
    
#Test 2
dies_ok{generate2007()} 'no arguments';
    
#Test 3
dies_ok{generate2007(1501721)} 'too long';

SKIP: {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    skip $msg, 9991 unless $ENV{TEST_AUTHOR};
    
    #Test 4
    is(generate2007(150172, 'female'), 4993, 'Valid female serial numbers series 1, 2 and 3, scalar context');
    
    #Test 5
    is(generate2007(150172, 'male'), 4994, 'Valid male serial numbers series 1, 2 and 3, scalar context');
    
    #Test 6
    is(generate2007(150172), 9987, 'Valid male and female serial numbers series 1, 2 and 3, scalar context');
    
    #Test 7-9994
    ok(my @cprs = generate2007(150172), 'Valid male and female serial numbers series 1, 2 and 3, list context');
    
    foreach (@cprs) {
        ok(validate2007($_), "Validating: $_");
    }
};