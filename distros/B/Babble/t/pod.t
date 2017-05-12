#! perl -w
use strict;
use Test::More;

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok ();

# arch-tag: 15c4c9de-1d6c-4a0f-b6c7-48e02067fdf6
