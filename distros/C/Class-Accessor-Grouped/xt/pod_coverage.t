use strict;
use warnings;
use Test::More;
BEGIN {
  eval 'use Test::Pod::Coverage 1.04; 1' or
    plan skip_all => 'Test::Pod::Coverage 1.04 not installed';

  eval 'use Pod::Coverage 0.14; 1'
    or plan skip_all => 'Pod::Coverage 0.14 not installed';
}

my $trustme = {
  trustme => [qr/^(g|s)et_component_class$/]
};

all_pod_coverage_ok($trustme);
