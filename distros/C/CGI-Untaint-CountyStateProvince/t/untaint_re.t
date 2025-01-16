#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

# Load the package containing the methods to test
use_ok('CGI::Untaint::CountyStateProvince');

# Test _untaint_re
subtest '_untaint_re regex test' => sub {
    my $untaint_re = CGI::Untaint::CountyStateProvince::_untaint_re(); # Assuming it's accessible
    ok($untaint_re, '_untaint_re returns a regex');

    like('hello world', $untaint_re, 'Matches valid input with letters and spaces');
    unlike('hello123', $untaint_re, 'Does not match input with numbers');
    unlike('hello@world', $untaint_re, 'Does not match input with special characters');
    unlike('', $untaint_re, 'Does not match empty input');
};

done_testing();
