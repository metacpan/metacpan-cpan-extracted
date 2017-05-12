use strict;
use Test::More;

eval "use Test::Pod";
plan skip_all => "Test::Pod required for pod check" if $@;

all_pod_files_ok ();
