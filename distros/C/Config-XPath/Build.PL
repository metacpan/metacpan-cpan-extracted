use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Config::XPath',
   dist_version_from => 'lib/Config/XPath.pm',
   configure_requires => {
      'Module::Build' => '0.2808', # perl5.10.0
   },
   requires => {
      'XML::XPath' => 0
   },
   build_requires => {
      'Test::More' => 0,
      'Test::Exception' => 0,
      'Test::Refcount' => 0,
      'Test::Warn' => 0,
   },
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);
  
$build->create_build_script;
