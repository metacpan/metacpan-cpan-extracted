use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Catalyst::Plugin::Session::Store::CHI',
    license             => 'Artistic_2_0',
    dist_author         => q{Know Zero <KnowZero>},
    dist_version_from   => 'lib/Catalyst/Plugin/Session/Store/CHI.pm',
    release_status      => 'stable',
    create_readme => 1,
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'CHI'              => 0,
        'MRO::Compat'              => 0,
        'Catalyst::Plugin::Session::Store'              => 0,
        'Path::Class'              => 0,
        'File::Spec'              => 0,
        'Class::Data::Inheritable'              => 0,


    },
    add_to_cleanup     => [ 'Catalyst-Plugin-Session-Store-CHI-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
