use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Acme::Spinodal::Utils',
    license             => 'artistic_2',
    dist_author         => q{Michael Wambeek <mikewambeek@hotmail.co.uk>},
    dist_version   => '0.03',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    add_to_cleanup     => [ 'Acme-Spinodal-Utils-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
