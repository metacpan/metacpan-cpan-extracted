use strict;
use warnings;

use lib 'inc';
use Alien::make::Module::Build;

my $build = Alien::make::Module::Build->new(
   module_name => 'Alien::unibilium',
   tarball => 'unibilium-1.2.0.tar.gz',
   pkgconfig_module => "unibilium",
   pkgconfig_version => "1.2.0",

   build_requires => {
      'File::Basename' => 0,
      'File::Path' => '2.07',
      'File::Spec' => 0,
   },
   requires => {
      'ExtUtils::PkgConfig' => 0,
   },
   license => 'perl',
   create_makefile_pl => 'small',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
