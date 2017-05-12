use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Authen::Simple::Twitter',
    license             => 'perl',
    dist_author         => 'Dan Moore <dan@moore.cx>',
    dist_version_from   => 'lib/Authen/Simple/Twitter.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Authen::Simple::Adapter' => 0,
        'Net::Twitter' => 0,
    },
    add_to_cleanup      => [ 'Authen-Simple-Twitter-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
