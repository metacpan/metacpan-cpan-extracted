use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Acme::SexualReproduction',
    license             => 'perl',
    dist_author         => q{Ivan Krylov <krylov.r00t@gmail.com>},
    dist_version_from   => 'lib/Acme/SexualReproduction.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
	'IPC::Shareable' => 0,
    },
    add_to_cleanup      => [ 'Acme-SexualReproduction-*' ],
    create_makefile_pl => 'traditional',
    configure_requires => { 'Module::Build' => 0.40 },
);

$builder->create_build_script();
