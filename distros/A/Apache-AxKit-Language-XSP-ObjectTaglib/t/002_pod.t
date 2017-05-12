#!perl -wT
# $Id: /local/CPAN/Apache-AxKit-Language-XSP-ObjectTaglib/t/002_pod.t 1497 2005-03-05T17:05:21.898763Z claco  $
use strict;
use warnings;
use Test::More;

eval 'use Test::Pod 1.00';
plan skip_all => 'Test::Pod 1.00 required for testing pod syntax' if $@;

all_pod_files_ok();
