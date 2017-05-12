
use Module::Build;

Module::Build->new(
  module_name => 'Class::Lego::Constructor',
  dist_version_from => 'lib/Class/Lego/Constructor.pm',

  requires => {
    'strict'         => 0,
    'warnings'       => 0,

    'Scalar::Defer'  => 0.13,
    'Exporter::Lite' => 0,
    'SUPER'          => 0,
  },
  build_requires => {
    'Test::More'     => 0,

  },

  license => 'perl',
  dist_author  => 'Adriano R. Ferreira <ferreira@cpan.org>',

  create_readme => 1,
  create_makefile_pl => 'traditional',

)->create_build_script;
