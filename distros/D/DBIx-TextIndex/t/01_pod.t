use strict;
use warnings;

use Test::More;

eval "use Test::Pod 1.26";
plan skip_all => "Test::Pod 1.26 required for testing POD" if $@;
all_pod_files_ok();
