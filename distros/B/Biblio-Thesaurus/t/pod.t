use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
plan skip_all => "export AUTHOR_TEST for author tests" unless $ENV{AUTHOR_TEST};
all_pod_files_ok();
