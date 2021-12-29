use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
  module_name  => 'Crypt::Bcrypt',
  c_source     => ['src'],
  'build_requires' => {
    'Module::Build' => '0.28',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.28'
  },
  'requires' => {
    'Exporter' => '5.57',
    'MIME::Base64' => '2.21',
    'XSLoader' => '0',
    'strict' => '0',
    'warnings' => '0'
  },
);

$builder->create_build_script();

