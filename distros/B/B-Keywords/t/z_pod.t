# -*- perl -*-
use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
plan skip_all => "5.8 required for =encoding" if $] < 5.008;
all_pod_files_ok();
