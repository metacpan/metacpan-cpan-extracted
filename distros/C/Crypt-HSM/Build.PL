use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
  module_name  => 'Crypt::HSM',
  include_dirs => 'include',
  'build_requires' => {
    'File::Spec' => '0',
    'IO::Handle' => '0',
    'IPC::Open3' => '0',
    'Module::Build' => '0.28',
    'Test::More' => '0',
    'perl' => '5.010'
  },
  'configure_requires' => {
    'Module::Build' => '0.28'
  },
  'requires' => {
    'XSLoader' => '0',
    'perl' => '5.010',
    'strict' => '0',
    'warnings' => '0'
  },
);

$builder->create_build_script();

