use strict;
use Module::Build;
#created by eumm-migrate.pl

my $build = Module::Build->new(
  'dist_abstract' => 'Convert dates to seconds since epoch, for arbritrary epochs',
  'auto_configure_requires' => 0,
  'license' => 'perl',
  'dist_author' => 'Eugene van der Pijll (pijll@gmx.net)',
  'module_name' => 'DateTime::Format::Epoch',
  'requires' => {
    'DateTime' => '0.31',
    'Math::BigInt' => '1.66',
    'Params::Validate' => 0,
    'warnings' => 0,
    'perl' => 5.00503,
  },
  'build_requires' => {
    'Test::More' => 0,
  },
  'meta_merge' => {
    'resources' => {
      'repository' => 'http://github.com/chorny/DateTime-Format-Epoch'
    }
  },
  'dist_version_from' => 'lib/DateTime/Format/Epoch.pm',
  create_makefile_pl => 'traditional',
);

$build->create_build_script();
