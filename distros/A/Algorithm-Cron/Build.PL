use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Algorithm::Cron',
   requires => {
      'Time::timegm' => 0,
      'perl' => '5.008', # doesn't play with  use constant  from 5.6
   },
   build_requires => {
      'Test::Fatal' => 0,
      'Test::More' => '0.88', # done_testing
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
