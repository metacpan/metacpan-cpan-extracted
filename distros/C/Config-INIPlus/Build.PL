use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Config::INIPlus',
    license             => 'perl',
    dist_author         => 'Anthony Kilna <anthony@kilna.com>',
    dist_version_from   => 'lib/Config/INIPlus.pm',
    build_requires => {
        'Test::More' => 0,
		'File::Temp' => 0,
		'FindBin'    => 0,
    },
    requires => {
		'perl'         => '5.8.0',
        'IO::File'     => 0,
		'IO::String'   => 0,
		'Scalar::Util' => 0,
		'Carp'         => 0,
    },
    add_to_cleanup      => [ 'Config-INIPlus-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
