use strict;
use warnings;

use Module::Build qw();

my $build = Module::Build->new(
  license            => 'perl',
  module_name        => 'DBIx::Migration',
  configure_requires => {
    'CPAN::Meta::Converter' => 2.150010,
    'CPAN::Meta::YAML'      => 0.020,
    'Module::Build'         => 0.42,
    'JSON::PP'              => 4.16
  },
  test_requires => {
    'DBD::SQLite'       => 1.27,        # Supports foreign key constraints
    'DBD::Mock'         => 0,
    'Test::API'         => 0,
    'Test::DatabaseRow' => 0,
    'Test::Deep'        => 0,
    'Test::Fatal'       => 0,
    'Test::More'        => 1.001005,    # Subtests accept args
    'Test::Output'      => 0,
    'Test::PostgreSQL'  => 0
  },
  recommends => {
    'Test::Needs'         => 0,
    'Test::Pod'           => 1.26,
    'Test::Pod::Coverage' => 1.04,
    'Text::Table::Tiny'   => 1.02
  },
  requires => {
    'perl'                      => '5.8.9',
    'DBI'                       => 1.33,      # DBI::clone() is in use
    'File::Spec'                => 0,
    'Log::Any'                  => 1.044,     # Flexible naming of imported log object
    'Module::Load::Conditional' => 0.60,
    'Moo'                       => 0,
    'MooX::SetOnce'             => 0,
    'MooX::StrictConstructor'   => 0,
    'Path::Tiny'                => 0.062,
    'PerlX::Maybe'              => 0,
    'Pod::Find'                 => 0,
    'Pod::Usage'                => 2.05,      # Stop inheriting from Exporter
    'String::Expand'            => 0,
    'Try::Tiny'                 => 0,
    'Types::Path::Tiny'         => 0,
    'namespace::clean'          => 0
  },
  create_readme  => 1,
  script_files   => [ glob( 'script/*' ) ],
  test_files     => [ glob( 't/*.t' ) ],
  add_to_cleanup => [ 'cover_*', 'DBIx-Migration-*' ],
  meta_merge     => {
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
