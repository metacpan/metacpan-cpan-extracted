use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CSS::Adaptor::Whitelist',
    license             => 'perl',
    dist_author         => 'Oldrich Kruza <sixtease@cpan.org>',
    dist_version_from   => 'lib/CSS/Adaptor/Whitelist.pm',
    requires => {
        CSS => 1,
        parent => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'CSS-Adaptor-Whitelist-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
