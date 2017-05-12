#!perl -wT
# $Id: /local/CPAN/Catalyst-Model-NetBlogger/t/pod_syntax.t 1376 2005-11-19T03:45:12.647758Z claco  $
use strict;
use warnings;
use Test::More;

eval 'use Test::Pod 1.00';
plan skip_all => 'Test::Pod 1.00 not installed' if $@;

all_pod_files_ok();
