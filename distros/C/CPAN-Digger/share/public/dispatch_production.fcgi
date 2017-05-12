#!/usr/bin/env perl

# in the production environment
use lib '/home/gabor/perl5/local/lib/perl5';
use lib '/home/gabor/perl5/local/lib/perl5/x86_64-linux-gnu-thread-multi';

$ENV{CPAN_DIGGER_ENV} = 'production';
require 'dispatch.fcgi';
