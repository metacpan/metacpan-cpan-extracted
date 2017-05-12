
use strict;
use Test::More tests => 916;
use Test::Exception;

#Test 1, load test
use_ok('Business::DK::CPR', qw(validate1968));

#Test 2
dies_ok{Business::DK::CPR::generate1968()} 'no arguments';

#Test 3
dies_ok{Business::DK::CPR::generate1968(1501721)} 'too long';

SKIP: {    
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    skip $msg, 913 unless $ENV{TEST_AUTHOR};

    #Test 4
    is(Business::DK::CPR::generate1968(150172, 'female'), 456, 'Valid female serial numbers, scalar context');
    
    #Test 5
    is(Business::DK::CPR::generate1968(150172, 'male'), 453, 'Valid male serial numbers series 1, 2 and 3, scalar context');
    
    #Test 6
    is(Business::DK::CPR::generate1968(150172), 909, 'Valid male and female serial numbers, scalar context');
        
    #Test 7-916
    ok(my @cprs = Business::DK::CPR::generate1968(150172), 'Valid male and female serial numbers, list context');
    
    foreach (@cprs) {
        ok(validate1968($_), "Validating: $_");
    }
};