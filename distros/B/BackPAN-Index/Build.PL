use strict;
use lib 'inc';

use MyBuilder;

my $build = MyBuilder->new(
  license            => 'perl',
  module_name        => 'BackPAN::Index',
  dist_author        => [
      'Leon Brocard <acme@astray.com>',
      'Michael G Schwern <schwern@pobox.com>',
  ],

  requires           => {
    'App::Cache'            => '0.37',
    'CPAN::DistnameInfo'    => '0.09',
    CLASS                   => '1.00',
    'LWP::Simple'           => '0',
    'URI'                   => '1.54',
    'Archive::Extract'      => '0',
    'DBIx::Class'           => '0.08109',
    'DBD::SQLite'           => '1.25',
    'Mouse'		    => '0.64',
    'Path::Class'           => '0.17',
    autodie                 => '0',
    parent                  => '0',
    perl                    => '5.008001',
  },

  build_requires     => {
    'Test::More'            => '0.90',
    'Test::Compile'         => '0.11',
  },

  configure_requires => {
    'Module::Build'         => '0.340201',
  },

  recursive_test_files  => 1,

  meta_merge => {
      resources             => {
          bugtracker        => 'http://rt.cpan.org/Public/Dist/Display.html?Name=BackPAN-Index',
          repository        => 'http://github.com/acme/parse-backpan-packages',
      },
  },

  create_license        => 1,
  create_readme         => 1,
);
$build->create_build_script;
