use Test::More;

eval "use Test::Pod 1.4";
plan skip_all => 'Test::Pod 1.4 required' if $@;

all_pod_files_ok();
