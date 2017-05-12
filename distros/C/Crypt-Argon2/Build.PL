use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
  module_name  => 'Crypt::Argon2',
  c_source     => 'src',
  include_dirs => 'include',
  'build_requires' => {
    'Module::Build' => '0.28',
    'Test::More' => '0.89',
    'perl' => '5.006'
  },
  'configure_requires' => {
    'Module::Build' => '0.28',
    'perl' => '5.006'
  },
  'requires' => {
    'Exporter' => '5.57',
    'XSLoader' => '0',
    'perl' => '5.006',
    'strict' => '0',
    'warnings' => '0'
  },
);

$builder->create_build_script();
