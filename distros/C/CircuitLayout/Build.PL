use Module::Build;
my $build = new Module::Build
(
	module_name => 'CircuitLayout',
	license => 'artistic',
	requires => {
		perl => '5.6.0',
		Tk => '800.013',
		Tk::WorldCanvas => '1.2',
	},
    sign => 1,
);
$build -> create_build_script;

