use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Acme::FIREXFLY::Utils',
    license             => 'artistic_2',
    dist_author         => q{firexfly <code@firexfly.com>},
    dist_version_from   => 'lib/Acme/FIREXFLY/Utils.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0',
    },
    build_requires => {
        'Test::More' => '0',
    },
    requires => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    add_to_cleanup     => [ 'Acme-FIREXFLY-Utils-*' ],
);

$builder->create_build_script();
