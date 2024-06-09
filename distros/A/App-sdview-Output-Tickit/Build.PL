use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'App::sdview::Output::Tickit',
   requires => {
      perl => '5.026',
      'Object::Pad' => '0.805',

      'App::sdview::Style' => '0.12',
      'String::Tagged' => '0.23',
      'Tickit' => 0,
      'Tickit::Style' => 0,
      'Tickit::Widget::FloatBox' => 0,
      'Tickit::Widget::Scroller' => '0.32',
      'Tickit::Widget::Scroller::Item::RichText' => 0,
      'Tickit::Widget::Static' => 0,
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
