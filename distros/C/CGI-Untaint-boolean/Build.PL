use Module::Build;

my $build = Module::Build->new(
	module_name => 'CGI::Untaint::boolean',
	license     => 'perl',
	requires    =>
	{
		'CGI::Untaint' => '1.00',
	},
	build_requires     =>
	{
		'Scalar::Util'       => '',
		'Test::Simple'       => '0.47',
		'Test::CGI::Untaint' => '1.10',
	},
	dist_version_from => 'lib/CGI/Untaint/boolean.pm',
	create_makefile_pl => 'traditional',
	sign              => 1,
);

$build->create_build_script();
