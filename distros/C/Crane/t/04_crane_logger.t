#!/usr/bin/env perl
# -*- coding: utf-8 -*-


use t::lib::Crane::Logger;

use Test::More;


plan('tests' => 7);

can_ok('Crane::Logger', qw(
    log_fatal
    log_error
    log_warning
    log_info
    log_debug
    log_verbose
));

subtest('Fatal' => \&test_fatal);
subtest('Error' => \&test_error);
subtest('Warning' => \&test_warning);
subtest('Info' => \&test_info);
subtest('Debug' => \&test_debug);
subtest('Verbose' => \&test_verbose);

done_testing();
