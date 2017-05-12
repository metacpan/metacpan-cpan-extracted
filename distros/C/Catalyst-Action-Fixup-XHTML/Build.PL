use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Catalyst::Action::Fixup::XHTML',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/Catalyst/Action/Fixup/XHTML.pm',
    build_requires => {
        'Test::More' => 0,
        'Moose'      => 0,
        'MRO::Compat' => 0,
        'Catalyst::Runtime' => 0,
        'Catalyst::View::ContentNegotiation::XHTML' => '1.100',
    },
    add_to_cleanup      => [ 'Catalyst-Action-Fixup-XHTML-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
