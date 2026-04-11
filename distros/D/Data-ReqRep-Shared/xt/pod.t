use strict;
use warnings;
use Test::More;

plan skip_all => 'Test::Pod required' unless eval { require Test::Pod; 1 };
Test::Pod::all_pod_files_ok();
