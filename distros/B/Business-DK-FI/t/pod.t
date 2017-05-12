# $Id: pod.t 1697 2007-02-12 11:52:41Z jonasbn $ 

use Test::More;

eval "use Test::Pod 1.14";
plan skip_all => 'Test::Pod 1.14 required' if $@;
plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};

all_pod_files_ok();
