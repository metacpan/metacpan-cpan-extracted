#!/usr/bin/env perl -T

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use warnings;
use strict;

use Test::More;

eval { require Test::Pod::Coverage; };

if ( $@ ) {
  plan( skip_all => 'Test::Pod::Coverage not found'  );
}

Test::Pod::Coverage::all_pod_coverage_ok();
