#!perl -T
# vim:ts=4:sw=4:et:ft=perl:

use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
all_pod_files_ok();
