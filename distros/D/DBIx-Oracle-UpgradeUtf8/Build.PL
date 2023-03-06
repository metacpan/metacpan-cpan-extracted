use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DBIx::Oracle::UpgradeUtf8',
    license             => 'perl',
    dist_author         => 'Laurent Dami <dami@cpan.org>',
    dist_version_from   => 'lib/DBIx/Oracle/UpgradeUtf8.pm',

    requires => {
      'perl'                      => "5.010001",
      'utf8'                      => 0,
      'Scalar::Util'              => 0,
     },
    test_requires => {
      'Test::More'                => 0,
      'DBI'                       => 0,
      'DBD::Oracle'               => 0,
    },

    add_to_cleanup      => [ 'DBIx-Oracle-UpgradeUtf8-*' ],
    meta_merge => {
      resources => {
        repository => 'https://github.com/damil/DBIx-Oracle-UpgradeUtf8',
       }
     },
);

$builder->create_build_script();
