use strict;
use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'Algorithm::SVMLight',
   license => 'perl',
   extra_linker_flags => '-lsvmlight',
   extra_compiler_flags => '-Wall',
   create_makefile_pl => 'passthrough',
   build_requires => {
		      'Module::Build' => '0.21',
		      'Test::More' => 0,
		     },
  );

$build->create_build_script;
