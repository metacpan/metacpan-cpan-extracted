#!perl -wT
# $Id: /mirror/claco/Catalyst-Model-SVN/branches/devel-0.07-t0m/t/pod_syntax.t 694 2005-11-02T00:57:06.696032Z claco  $
use strict;
use warnings;
use Test::More;

eval 'use Test::Pod 1.00';
plan skip_all => 'Test::Pod 1.00 not installed' if $@;

all_pod_files_ok();
