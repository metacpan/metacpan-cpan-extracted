use strict;
use warnings;

use lib 'inc';
use Alien::make::Module::Build;

my $build = Alien::make::Module::Build->new(
   module_name => 'Alien::libtermkey',
   tarball => 'libtermkey-0.18.tar.gz',
   pkgconfig_module => "termkey",
   pkgconfig_version => "0.18",

   alien_requires => [
      [ any =>
         [ pkgconfig => "unibilium", atleast_version => "0.1.0" ],
         [ pkgconfig => "ncursesw" ],
         [ header => "curses.h" ],
      ],
   ],
   build_requires => {
      'File::Basename' => 0,
      'File::Path' => '2.07',
      'File::Spec' => 0,
   },
   license => 'perl',
   create_makefile_pl => 'small',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
