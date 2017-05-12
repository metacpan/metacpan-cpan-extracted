#!/usr/bin/perl
#$Id: pod.t,v 1.1.1.1 2004/11/21 15:47:22 simonflack Exp $
use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
