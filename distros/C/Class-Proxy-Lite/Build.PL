use Module::Build;
my $build = Module::Build->new (
	module_name => 'Class::Proxy::Lite',
	license => 'perl',
	requires => {},
);
$build->create_build_script;
