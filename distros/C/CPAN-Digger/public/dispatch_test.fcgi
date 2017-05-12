#!/usr/bin/env perl

# in the test environment
use lib '/home/gabor/perl5/local/lib/perl5';
use lib '/home/gabor/perl5/local/lib/perl5/x86_64-linux-gnu-thread-multi';

$ENV{CPAN_DIGGER_ENV} = 'test';
require 'dispatch.fcgi';
