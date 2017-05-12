use Module::Build;

my $build = Module::Build->new(
	module_name => 'Compress::LZW::Progressive',
	license => 'perl',
	requires => {
		'Test::Memory::Cycle' => 0,
		'Test::More' => 0,
	},
	recommends => {
		'Devel::Size' => 0,
	},
	sign => 1,
	create_makefile_pl => 'passthrough',
	create_readme => 1,
);

$build->create_build_script;
