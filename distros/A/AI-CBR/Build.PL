use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'AI::CBR',
    license             => 'perl',
    dist_author         => 'Darko Obradovic <dobradovic@gmx.de>',
    dist_version_from   => 'lib/AI/CBR.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'AI-CBR-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
