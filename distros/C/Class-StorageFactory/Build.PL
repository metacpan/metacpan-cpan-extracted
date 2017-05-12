use Module::Build;
use File::Spec::Functions 'catfile';

my $build = Module::Build->new(
	module_name => 'Class::StorageFactory',
	license     => 'perl',
	sign        => 1,
	requires    =>
	{
		'YAML'  => '0.35',
	},
	build_requires =>
	{
		'Test::Pod'           => '',
		'Test::Class'         => '',
		'Test::Simple'        => '0.47',
		'Test::Exception'     => '',
		'Test::Pod::Coverage' => '',
	},
	dist_version_from => catfile(qw( lib Class StorageFactory.pm )),
);

$build->create_build_script();
