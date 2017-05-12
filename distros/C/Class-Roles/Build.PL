use Module::Build;

my $build = Module::Build->new(
	module_name => 'Class::Roles',
	license     => 'perl',
	requires    => {
		Test::Simple     => '0.47',
		Test::Exception  => '',
	},
	dist_version_from => 'lib/Class/Roles.pm',
);

$build->create_build_script;
