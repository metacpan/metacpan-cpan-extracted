## no critic(RCS,VERSION,explicit,Module)
use strict;
use warnings;

use Test::More;

if ( $ENV{RELEASE_TESTING} ) {
    eval 'use Test::Pod 1.00';    ## no critic (eval)
    if ($@) { plan skip_all => 'Test::Pod 1.00 required for testing POD'; }
}
else {
    plan skip_all => 'Skip Test::Pod tests unless environment variable '
      . 'RELEASE_TESTING is set.';
}

all_pod_files_ok();
