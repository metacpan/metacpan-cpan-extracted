use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Data::Context::Loader::DB',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/Data/Context/Loader/DB.pm',
    requires          => {
        'perl'                  => '5.008',
        'DBIx::Class::Core'     => 0,
        'DBIx::Class::Schema'   => 0,
        'Data::Context'         => '0.3',
        'Data::Context::Finder' => '0.3',
        'Data::Context::Loader' => '0.3',
        'Data::Context::Util'   => '0.3',
        'JSON::XS'              => 0,
        'Moose'                 => 0,
        'MooseX::NonMoose'      => '0.26',
        'namespace::autoclean'  => 0,
        'version'               => 0,
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More'     => '0.88',
        'Test::Warnings' => '0.026',
    },
    add_to_cleanup     => [ 'Data-Context-Loader-DB-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/Data-Context-Loader-DB.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data::Context::Loader::DB',
        },
    },
);

$builder->create_build_script();
