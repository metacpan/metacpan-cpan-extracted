use v5;
use strict;
use warnings;

use lib 'inc';
use Alien::make::Module::Build;

my $build = Alien::make::Module::Build->new(
   module_name => 'Alien::libvterm',
   tarball => 'libvterm-0.1.4.tar.gz',
   pkgconfig_module => "vterm",
   pkgconfig_version => "0.1",
   use_bundled => ( scalar grep { $_ eq "--use-bundled" } @ARGV ),

   build_requires => {
      'File::Basename' => 0,
      'File::Path' => '2.07',
      'File::Spec' => 0,
   },
   configure_requires => {
      'perl' => '5.010', # //
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
