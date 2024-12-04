use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'App::csvtool',
   requires => {
      'perl' => '5.026',
      'experimental' => 0,

      'Commandable::Finder::Packages' => '0.14',
      'Commandable::Invocation' => '0.03',
      'File::Basename' => 0,
      'Getopt::Long' => 0,
      'List::UtilsBy' => 0,
      'POSIX::strptime' => 0,
      'Text::CSV' => 0,
      'Time::timegm' => 0,
   },
   test_requires => {
      'Test2::V0' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
