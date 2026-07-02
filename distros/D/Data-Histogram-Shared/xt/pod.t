use strict; use warnings; use Test::More;
plan skip_all => 'author test (set AUTHOR_TESTING=1)' unless $ENV{AUTHOR_TESTING};
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required" if $@;
all_pod_files_ok();
