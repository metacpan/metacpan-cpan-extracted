use Module::Build;

my $build = new Module::Build(
	module_name => 'CLI::Application',
	license => 'artistic_2',
	requires => {
		perl => '5.8.5',
		'Text::Table' => 0,
		'Attribute::Handlers' => 0,
		'Module::Load' => 0,
	},
);

$build->create_build_script;
