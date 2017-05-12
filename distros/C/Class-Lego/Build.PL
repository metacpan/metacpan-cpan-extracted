
use Module::Build;

Module::Build->new(
  dist_name => 'Class-Lego',
  dist_version_from => 'lib/Class/Lego.pm',
  license => 'perl',
  author => 'Adriano Ferreira <ferreira@cpan.org>',
  requires => {
	       'Sub::Exporter' => 0,
	       'Sub::Install'  => 0,
	       'Scalar::Defer' => 0.13,
               'Carp'          => 0,
  },
  build_requires => {
               'Test::More'    => 0,
  },

  create_makefile_pl => 'traditional',
  create_readme => 1,

)->create_build_script;
