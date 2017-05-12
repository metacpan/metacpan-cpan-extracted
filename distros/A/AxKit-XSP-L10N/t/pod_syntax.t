#!perl -wT
# $Id: /local/CPAN/AxKit-XSP-L10N/t/pod_syntax.t 1396 2005-03-25T03:58:41.995755Z claco  $
use strict;
use warnings;
use Test::More;

eval 'use Test::Pod 1.00';
plan skip_all => 'Test::Pod 1.00 not installed' if $@;

all_pod_files_ok();
