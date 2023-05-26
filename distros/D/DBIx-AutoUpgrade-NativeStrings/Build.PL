use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DBIx::AutoUpgrade::NativeStrings',
    license             => 'perl',
    dist_author         => 'Laurent Dami <dami@cpan.org>',
    dist_version_from   => 'lib/DBIx/AutoUpgrade/NativeStrings.pm',

    requires => {
      'perl'                      => "5.010001",
      'utf8'                      => 0,
      'Scalar::Util'              => 0,
      'Encode'                    => 0,
      'Encode::Locale'            => 0,
      'DBI'                       => 0,
     },
    build_requires => {
      'Test::More'                => 0,
      'DBI'                       => 0,
      'Getopt::Long'              => 0,
      'Encode'                    => 0,
      'DBD::SQLite'               => 1.68,
    },

    add_to_cleanup      => [ 'DBIx-AutoUpgrade-NativeStrings-*' ],
    meta_merge => {
      resources => {
        repository => 'https://github.com/damil/DBIx-AutoUpgrade-NativeStrings',
        bugtracker => 'https://github.com/damil/DBIx-AutoUpgrade-NativeStrings/issues',
       }
     },
);

$builder->create_build_script();
