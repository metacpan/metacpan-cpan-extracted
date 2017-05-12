use Test::More;
eval "use Test::Pod";
plan skip_all => 'Needs Test::Pod' if $@;
all_pod_files_ok();

