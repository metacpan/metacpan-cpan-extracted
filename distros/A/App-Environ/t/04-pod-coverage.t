use 5.008000;
use strict;
use warnings;

use Test::More;
eval "use Test::Pod::Coverage 1.08";

if ( $@ ) {
  plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage";
}

all_pod_coverage_ok();
