# $Id: 99_pod.t 22 2012-07-05 21:36:33Z jim $

use Test::More;

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
