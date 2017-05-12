use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Context::Set',
    license             => 'perl',
    dist_author         => q{Jerome Eteve <jerome.eteve@gmail.com>},
    dist_version_from   => 'lib/Context/Set.pm',
    build_requires => {
        'Test::More' => 0,
        'DBD::SQLite' => 1.35,
        'DBIx::Class::Schema::Loader' => 0.07010,
    },
    requires => {
        'perl' => 5.006,
        'Moose' => 2.0401,
        'Log::Log4perl' => 1.29,
    },
    add_to_cleanup      => [ 'Context-Set-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
