use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'App::MatrixTool',
   requires => {
      'File::Slurper' => 0,
      'Future' => '0.33',
      'IO::Async::Resolver' => '0.68',
      'IO::Async::Resolver::DNS' => '0.06',
      'IO::Async::SSL' => 0,
      'JSON' => 0,
      'List::Util' => '1.29',
      'MIME::Base64' => 0,
      'Module::Pluggable::Object' => 0,
      'Module::Runtime' => 0,
      'Net::Async::HTTP' => '0.40',
      'Protocol::Matrix' => 0,
      'Protocol::Matrix::HTTP::Federation' => 0,
      'Struct::Dumb' => 0,
      'URI::Escape' => 0,
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
