use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Acme::Magic::Pony',
    license             => 'perl',
    dist_author         => 'Jeff Lavallee <jeff@zeroclue.com>',
    dist_version_from   => 'lib/Acme/Magic/Pony.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'CPAN' => '>= 1.93',
    },
    add_to_cleanup      => [ 'Acme-Magic-Pony-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
