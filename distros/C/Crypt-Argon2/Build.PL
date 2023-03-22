use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
  module_name  => 'Crypt::Argon2',
  c_source     => 'src',
  include_dirs => 'include',
  'build_requires' => {
    'Module::Build' => '0.28',
    'Test::More' => '0.90',
    'perl' => '5.006'
  },
  'configure_requires' => {
    'Module::Build' => '0.28',
    'perl' => '5.006'
  },
  'requires' => {
    'Exporter' => '5.57',
    'Time::HiRes' => '0',
    'XSLoader' => '0',
    'perl' => '5.006',
    'strict' => '0',
    'warnings' => '0'
  },
);

if ($^O ne 'MSWin32') {
	$builder->extra_compiler_flags('-pthread');
	$builder->extra_linker_flags('-pthread');
}

$builder->create_build_script();
