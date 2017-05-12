#!/usr/bin/env perl -w

use strict;
use lib "t/lib";
use Test::More;
use Test::App::EventStreamr::Logger;

#TODO: Add 'no_end_test' due to Double END Block issue
use Test::Warnings ':no_end_test';

my $logger = Test::App::EventStreamr::Logger->new();

subtest 'Logger Instantiation' => sub {
  can_ok($logger, qw(
    log trace debug info warn error fatal
    is_trace is_debug is_info is_warn is_error is_fatal
    logexit logwarn error_warn logdie error_die
    logcarp logcluck logcroak logconfess
  ));
};

done_testing();
