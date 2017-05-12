use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'App::Devel::MAT::Explorer::GTK',

   requires => {
      'Devel::MAT' => '0.23',
      'File::ShareDir' => 0,
      'Glib' => 0,
      'Gtk2' => 0,
      'Gtk2::SimpleList' => 0,
      'List::Util' => '1.29',
      'List::UtilsBy' => 0,
      'Struct::Dumb' => 0,
   },
   auto_configure_requires => 0, # Don't add M::B
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
