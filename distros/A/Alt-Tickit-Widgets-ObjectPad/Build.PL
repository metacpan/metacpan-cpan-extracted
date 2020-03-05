use strict;
use warnings;

use Module::Build;

my $alt = $ENV{PERL_ALT_INSTALL} || '';

my $build = Module::Build->new(
   module_name => 'Alt::Tickit::Widgets::ObjectPad',
   dist_abstract => "a collection of Tickit::Widget implementations (using Object::Pad)",
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   requires => {
      'perl' => '5.010',
      'List::Util' => '1.33',
      'Object::Pad' => '0.09',
      'Parser::MGC' => 0,
      'Struct::Dumb' => 0,
      'Tickit::Event' => '0.63',
      'Tickit::RenderBuffer' => 0,
      'Tickit::Utils' => '0.29',
      'Tickit::Window' => '0.57', # $win->bind_event
   },
   test_requires => {
      'Test::Identity' => 0,
      'Test::More' => '0.88', # done_testing
      'Test::Refcount' => 0,
   },
   destdir => ( $alt ? $alt eq 'OVERWRITE' ? '' : $alt : 'no-install-alt' ),
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
