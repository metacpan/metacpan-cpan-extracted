use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Catalyst::Model::DBIDM',
    license             => 'perl',
    dist_author         => 'Cedric Bouvier <cbouvi@cpan.org>',
    dist_version_from   => 'lib/Catalyst/Model/DBIDM.pm',
    build_requires => {
        'Test::More'      => 0,
        'DBIx::DataModel' => 1.0,
        'DBI'             => 0,
        'Catalyst::Model' => 0,
    },
    add_to_cleanup      => [ 'Catalyst-Model-DBIDM-*' ],
);

$builder->create_build_script();
