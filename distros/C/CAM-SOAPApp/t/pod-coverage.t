#!perl -T

use Test::More;
eval "use Pod::Coverage 0.17 ()";
plan skip_all => "Optional Pod::Coverage 0.17 not found -- no big deal" if $@;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Optional Test::Pod::Coverage 1.04 not found -- no big deal" if $@;
all_pod_coverage_ok();
