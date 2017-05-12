#!perl -wT
# $Id: /local/CPAN/AxKit-XSP-Currency/t/pod_syntax.t 1434 2005-03-05T01:08:13.559154Z claco  $
use strict;
use warnings;
use Test::More;

eval 'use Test::Pod 1.00';
plan skip_all => 'Test::Pod 1.00 not installed' if $@;

all_pod_files_ok();
