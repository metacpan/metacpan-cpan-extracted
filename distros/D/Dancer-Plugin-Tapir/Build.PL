use Module::Build;

my $build = Module::Build->new(
	module_name => 'Dancer::Plugin::Tapir',
	license     => 'perl',
	sign        => 1,
	create_readme => 1,
	configure_requires => {
		'Module::Build' => 0.4,
	},
	build_requires => {
		'Test::Exception' => 0,
	},
	requires             => {
		'perl'           => 5.006,
		'Tapir'          => 0.03,
		'Capture::Tiny'  => 0,
		'Dancer'         => 1.3100,
		'JSON'           => 0,
		'JSON::XS'       => 0,
		'Thrift::Parser' => 0,
		'Try::Tiny'      => 0,
	},
	create_makefile_pl => 'small',
	meta_merge => {
		resources => {
			repository => "http://github.com/ewaters/dancer-plugin-tapir",
			bugtracker => "http://github.com/ewaters/dancer-plugin-tapir/issues?labels=bug",
		},
	},
);

$build->create_build_script;

