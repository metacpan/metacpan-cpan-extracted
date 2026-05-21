use strict;
use warnings;
use Test::More;

eval { require Test::Pod; Test::Pod->VERSION(1.22); 1 }
    or plan skip_all => 'Test::Pod 1.22+ required for POD syntax tests';

Test::Pod::all_pod_files_ok();
