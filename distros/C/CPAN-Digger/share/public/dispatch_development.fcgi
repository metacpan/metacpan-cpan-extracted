#!/usr/bin/env perl

# in the development environment
use lib '/home/gabor/perl5/lib/perl5';
use lib '/home/gabor/perl5/lib/perl5/x86_64-linux-gnu-thread-multi';

$ENV{CPAN_DIGGER_ENV} = 'development';
require 'dispatch.fcgi';
