use strict;
use warnings;
use Test::More;

plan skip_all => "Test::Pod 1.14+ not installed" unless
    eval "use Test::Pod 1.14; 1";

all_pod_files_ok();

done_testing();
