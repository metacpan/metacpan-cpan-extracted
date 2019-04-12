use strict;
use warnings;

use Test::More;

eval 'use Test::Pod';
plan skip_all => 'Test::Pod is required for testing POD' if $@;

all_pod_files_ok();

