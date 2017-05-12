use Module::Build;

my $build = Module::Build->new(
	license            => 'perl',
	dist_author        => 'Dave Cross <dave@mag-sol.com>',
        module_name        => 'Calendar::Simple',
	requires           => {
                perl                  => '5.6.0',
		Carp                  => 0,
		'Time::Local'         => 0,
                Config                => 0,
	},
	recommends         => {
		DateTime              => 0,
	},
        build_requires     => {
        	'Test::More'          => 0,
        },
	build_recommends   => {
		'Test::Pod'           => 0,
		'Test::Pod::Coverage' => 0,
	},
        create_makefile_pl => 'traditional',
        script_files       => [ 'bin/pcal' ],
);

$build->create_build_script;
