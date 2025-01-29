use strict;
use warnings;

use Module::Build qw();

my $build = Module::Build->new(
  create_makefile_pl => 'passthrough',
  license            => 'perl',
  module_name        => 'DBIx::Migration',
  configure_requires => {
    'CPAN::Meta::Converter' => 2.15,
    'Module::Build'         => 0.42
  },
  test_requires => {
    'DBD::SQLite'      => 0,
    'Test::PostgreSQL' => 0
  },
  recommends => {
    'Test::Needs'         => 0,
    'Test::Pod'           => 1.26,
    'Test::Pod::Coverage' => 1.04
  },
  requires => {
    'File::Slurp'           => 0,
    'File::Spec'            => 0,
    'DBI'                   => 1.33,    # DBI::clone() is in use
    'Class::Accessor::Fast' => 0
  },
  create_readme => 1,
  script_files  => [ glob( 'script/*' ) ],
  test_files    => [ glob( 't/*.t' ) ],
  meta_merge    => {
    'meta-spec' => {
      version => 2
    },
    resources => {
      repository => {
        url  => 'git://github.com/XSven/perl-dbix-migration.git',
        type => 'git'
      },
      bugtracker => {
        web => 'https://github.com/XSven/perl-dbix-migration/issues'
      }
    }
  }
);

$build->create_build_script;
