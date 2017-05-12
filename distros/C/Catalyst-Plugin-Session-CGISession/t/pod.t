#!perl -T

use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
plan skip_all => "Set TEST_POD environment variable if pod testing desired" 
    unless $ENV{'TEST_POD'};
all_pod_files_ok();
