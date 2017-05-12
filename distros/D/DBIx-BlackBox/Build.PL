use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DBIx::BlackBox',
    license             => 'perl',
    dist_author         => q{Alex J. G. Burzyński <ajgb@cpan.org>},
    dist_version_from   => 'lib/DBIx/BlackBox.pm',
    dist_abstract       => 'Access database with stored procedures only',
    build_requires => {
        'Test::More' => 0.94,
    },
    requires => {
        'Moose' => 0.98,
        'MooseX::Role::Parameterized' => 0.18,
        'namespace::autoclean' => 0.09,
        'DBIx::Connector' => 0.33,
        'DBI' => 1.609,
        'Module::Find' => 0.08,
        'DBD::Sybase' => 1.09,
    },
    add_to_cleanup      => [ 'DBIx-BlackBox-*' ],
    create_makefile_pl => 'traditional',
    create_licence => 1,
    meta_add => {
        resources => {
            repository => 'git://github.com/ajgb/dbix-blackbox.git',
        },
    },
);

$builder->create_build_script();
