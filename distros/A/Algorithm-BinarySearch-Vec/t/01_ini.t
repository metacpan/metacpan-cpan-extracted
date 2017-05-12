# -*- Mode: CPerl -*-
# t/01_ini.t; just to load module(s) by using it (them)

use Test::More tests => 2;

use_ok 'Algorithm::BinarySearch::Vec';

no warnings 'once';
SKIP: {
  skip("XS support not available", 1) if (!$Algorithm::BinarySearch::Vec::HAVE_XS);
  ok($Algorithm::BinarySearch::Vec::HAVE_XS, "HAVE_XS");
}

# end of t/01_ini.t
