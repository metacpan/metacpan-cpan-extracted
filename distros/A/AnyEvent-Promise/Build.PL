use 5.008;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'AnyEvent::Promise',
    license => 'mit',
    dist_author => q{Anthony Johnson <aj@ohess.org>},
    dist_version_from => 'lib/AnyEvent/Promise.pm',
    release_status => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'AnyEvent' => 0,
        'Try::Tiny' => 0,
        'Carp' => 0
    },
    add_to_cleanup => [ 'AnyEvent-Promise-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
