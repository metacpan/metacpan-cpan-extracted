use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'App::MatrixClient',
   requires => {
      'Convert::Color::XTerm' => 0,
      'Data::Dump' => 0,
      'Event::Distributor' => '0.04',
      'Future' => 0,
      'Image::ExifTool' => 0,
      'IO::Async::Loop' => 0,
      'IO::Async::Timer::Countdown' => 0,
      'List::Util' => '1.33',
      'Net::Async::Matrix' => 0,
      'Net::Async::Matrix::Utils' => 0,
      'POSIX' => 0,
      'String::Tagged' => '0.11',
      'Tickit' => '0.48',
      'Tickit::Async' => 0,
      'Tickit::Console' => '0.07',
      'Tickit::Widget::FloatBox' => 0,
      'Tickit::Widget::Frame' => '0.31',
      'Tickit::Widget::GridBox' => 0,
      'Tickit::Widget::ScrollBox' => 0,
      'Tickit::Widget::Static' => 0,
      'Tickit::Widget::VBox' => 0,
      'YAML' => 0,
      'curry' => 0,

      'perl' => '5.014', # s///r
   },
   test_requires => {
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
