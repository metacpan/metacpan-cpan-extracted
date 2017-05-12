# This test is only for raising Kwalitee
# because testing POD is done with Module::Build using "Build testpod".
use strict;
use warnings;
use Test::More;
plan skip_all => "POD testing is only for release testing" unless $ENV{RELEASE_TESTING};

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
