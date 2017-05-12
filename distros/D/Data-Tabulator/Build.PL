use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Data::Tabulator',
    license             => 'perl',
    dist_author         => 'Robert Krimen <rkrimen@cpan.org>',
    dist_version_from   => 'lib/Data/Tabulator.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Scalar::Util' => 0,
        'Class::Accessor::Fast' => 0,
        'Sub::Exporter' => 0,
        'POSIX' => 0,
    },
    add_to_cleanup      => [ 'Data-Tabulator-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
