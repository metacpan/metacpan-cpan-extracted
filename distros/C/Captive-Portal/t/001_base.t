use Test::More;
use Module::Build;
use strict;
use warnings;

use_ok('Captive::Portal');
use_ok('Authen::Simple');

my $builder        = Module::Build->current;
my $test_radius_modules     = $builder->notes('test_radius_modules');

SKIP: {
  skip '-> no radius module tests', 2, unless $test_radius_modules;
  use_ok('Authen::Radius');
  use_ok('Authen::Simple::RADIUS');
}

done_testing(4);
