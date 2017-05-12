#!perl -wT
# $Id: /local/CPAN/AxKit-XSP-Minisession/t/002_pod.t 1418 2005-03-05T18:07:22.924154Z claco  $
use strict;
use warnings;
use Test::More;

eval 'use Test::Pod 1.00';
plan skip_all => 'Test::Pod 1.00 required for testing pod syntax' if $@;

all_pod_files_ok();
