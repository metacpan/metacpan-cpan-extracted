use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Audio::Radio::Sirius',
    license             => 'perl',
    dist_author         => 'Jamie Tatum <jtatum@gmail.com>',
    dist_version_from   => 'lib/Audio/Radio/Sirius.pm',
    requires => {
        'Test::More' => 0,
	'perl' => '5.8.0',
	'Carp' => 0,
	'Time::HiRes' => 0,
    },
    add_to_cleanup      => [ 'Audio-Radio-Sirius-*' ],
    create_makefile_pl	=> 'passthrough',
);

$builder->create_build_script();
