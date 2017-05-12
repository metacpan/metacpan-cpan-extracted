#!/usr/bin/env perl -w

use Test::More;

eval "use Test::Pod 1.22; 1"
	or plan skip_all => "Test::Pod 1.22 required for testing POD";

all_pod_files_ok();

exit 0;
require Test::NoWarnings;
