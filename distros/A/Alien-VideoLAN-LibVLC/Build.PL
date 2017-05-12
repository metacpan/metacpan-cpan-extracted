use strict;
use warnings;
use Module::Build 0.20;

my $builder = Module::Build->new(
    module_name         => 'Alien::VideoLAN::LibVLC',
    license             => 'perl',
    dist_author         => q{Alexey Sokolov <alexey@alexeysokolov.co.cc>},
	dist_abstract       => 'Find installed LibVLC',
    dist_version_from   => 'lib/Alien/VideoLAN/LibVLC.pm',
	configure_requires => {
		'Module::Build' => '0.20',
	},
    build_requires => {
		'Module::Build' => '0.20',
        'Test::More' => 0,
    },
	requires       => {
		'ExtUtils::PkgConfig' => 0,
	},
    add_to_cleanup      => [ 'Alien-VideoLAN-LibVLC-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
