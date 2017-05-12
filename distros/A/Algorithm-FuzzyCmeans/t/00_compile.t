use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Algorithm::FuzzyCmeans' }
BEGIN { use_ok 'Algorithm::FuzzyCmeans::Distance::Cosine' }
BEGIN { use_ok 'Algorithm::FuzzyCmeans::Distance::Euclid' }
