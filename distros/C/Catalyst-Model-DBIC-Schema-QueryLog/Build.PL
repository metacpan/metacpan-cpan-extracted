use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Catalyst::Model::DBIC::Schema::QueryLog',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/Catalyst/Model/DBIC/Schema/QueryLog.pm',
    create_makefile_pl  => 'traditional',
    build_requires => {
        'Test::More' => 0,
        'Catalyst'  => 0,
        'Moose'     => 0,
        'DBIx::Class::QueryLog' => 0,
        'Catalyst::Model::DBIC::Schema' => 0,
        'MooseX::Emulate::Class::Accessor::Fast'  => 0,
        'Catalyst::Component::InstancePerContext' => 0,
    },
    add_to_cleanup      => [ 'Catalyst-Model-DBIC-Schema-QueryLog-*' ],
);

$builder->create_build_script();
