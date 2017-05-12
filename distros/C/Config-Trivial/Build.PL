#	$Id: Build.PL 67 2014-05-23 12:40:55Z adam $;

use strict;
use Module::Build;

my $build = Module::Build->new(
	module_name => 'Config::Trivial',
	license     => 'lgpl3',
	requires    => {
		'perl'  => '5.010',
	},
    configure_requires => {
        'Module::Build'    => '0.4',
    },
    build_requires => {
        'Module::Build' => 0.40,
        'IO::Capture'   => 0,
        'Test::Pod'     => 0,
        'Pod::Coverage' => 0,
        'Test::Pod::Coverage'   => 0,
    },
);

$build->create_build_script;
