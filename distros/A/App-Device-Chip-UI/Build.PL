#!/usr/bin/perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'App::Device::Chip::UI',
   requires => {
      'Device::Chip::Adapter' => 0,
      'Object::Pad' => '0.32',
      'Syntax::Keyword::Try' => '0.18',
      'Tickit' => 0,
      'Tickit::Widgets' => 0,

      ( map {( "Tickit::Widget::$_" => 0 )}
         qw( Button CheckButton Choice Entry GridBox Static Tabbed VBox ) ),

      'perl' => '5.026',
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
