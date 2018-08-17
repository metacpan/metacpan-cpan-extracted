#perl -T 

use strict;
use Test::More;
eval "use Test::Pod 1.18";
plan skip_all => "Test::Pod 1.18 required for testing POD" if $@;
plan skip_all => "No Developer Tests for non-developers" unless $ENV{AUTHOR_TESTING};

all_pod_files_ok();
