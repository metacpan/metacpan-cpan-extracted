#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Code::TidyAll qw(tidyall_ok);

subtest "tidy" => sub {
    tidyall_ok();
};

done_testing;

