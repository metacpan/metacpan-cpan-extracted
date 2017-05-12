#!perl -T

use Test::More;
eval "use Test::Pod::Coverage";
eval "use Pod::Coverage::Moose";

all_pod_coverage_ok
  ({
    coverage_class => "Pod::Coverage::Moose",
   });
