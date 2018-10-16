use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Data::Context',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/Data/Context.pm',
    requires          => {
        'perl'                         => 5.010,
        'Class::Inspector'             => 0,
        'Clone'                        => 0,
        'Hash::Merge'                  => 0,
        'IO::String'                   => 0,
        'List::MoreUtils'              => 0,
        'List::Util'                   => 0,
        'Moose'                        => 0,
        'Moose::Util::TypeConstraints' => 0,
        'namespace::autoclean'         => 0,
        'Path::Tiny'                   => 0,
        'Scalar::Util'                 => 0,
        'version'                      => 0,
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More'     => '0.88',
        'Test::Warn'     => 0,
        'Test::Warnings' => '0.026',
        'AnyEvent'       => 0,
        'AnyEvent::HTTP' => 0,
    },
    recommends => {
        'JSON::XS'           => 0,
        'YAML::XS'           => 0,
        'XML::Simple'        => 0,
        'Test::Spelling'     => 0,
        'Test::Perl::Critic' => 0,
        'Test::Kwalitee'     => 0,
        'Pod::Coverage'      => 0,
    },
    add_to_cleanup     => [ 'Data-Context-*' ],
    create_license     => 1,
    meta_merge         => {
        resources => {
            repository => 'git://github.com/ivanwills/Data-Context.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data::Context',
        },
    },
);

$builder->create_build_script();
