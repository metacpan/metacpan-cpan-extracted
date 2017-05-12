use strict;

use Test::More;

eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
eval { require Pod::Simple };
plan skip_all => "Pod::Simple 3.21 has bugs"
 if $Pod::Simple::VERSION == 3.21;

all_pod_files_ok();
