#!perl -T

use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Optional Test::Pod 1.14 not found -- no big deal" if $@;
all_pod_files_ok();
