
use strict;
use Test::More tests => 8;
use Test::Exception;

#Test 1, load test
use_ok('Business::DK::CPR', qw(generate));

#Test 2
dies_ok{generate()} 'no arguments';

#Test 3
dies_ok{generate(1501721)} 'too long';

SKIP: {
    my $msg = 'Author test. Set TEST_AUTHOR to a true value to enable';
    skip $msg, 5 unless $ENV{TEST_AUTHOR};
    
    #Test 4
    is(generate(150172, 'female'), 4993, 'Valid female serial numbers series 1, 2 and 3, scalar context');
    
    #Test 5
    is(generate(150172, 'male'), 4994, 'Valid male serial numbers series 1, 2 and 3, scalar context');
    
    #Test 6
    is(generate(150172), 9987, 'Valid male and female serial numbers series 1, 2 and 3, scalar context');
    
    #Test 7
    ok(my @cprs = generate(150172), 'Valid male and female serial numbers series 1, 2 and 3, list context');
	
	#Test 8
	is(scalar @cprs, 9987, 'asserting number of elements in array');
};