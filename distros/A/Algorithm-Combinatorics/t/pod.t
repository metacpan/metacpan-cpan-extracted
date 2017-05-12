#!perl

use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing Pod" if $@;

all_pod_files_ok();