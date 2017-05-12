use Module::Build;
my $build = Module::Build->new(
	module_name				=> 'CSDPR_Test',
	license					=> 'perl',
	create_readme			=>  1,
    create_makefile_pl      => 'passthrough',
	requires				=> {
			'Carp'				=> 0,
			'Hash::Util'		=> 0.05,
		},
    build_requires          => {
            'stuff'             => '1234',
        },
	recommends				=> {
			'Test::Files'		=> 0,
		},
);

$build->create_build_script;

