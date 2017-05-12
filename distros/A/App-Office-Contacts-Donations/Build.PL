use Module::Build;

my($builder) = Module::Build -> new
(
	module_name    => 'App::Office::Contacts::Donations',
	license        => 'artistic',
	dist_abstract  => 'A web-based donations manager',
	dist_author    => 'Ron Savage <ron@savage.net.au>',
	build_requires =>
	{
		Test::Simple => 0.94,
		Test::Pod    => 1.41,
	},
	requires =>
	{
		App::Office::Contacts => 1.10,
		Moose                 => 0.98,
		namespace::autoclean  => 0.09,
		Scalar::Util          => 1.23,
	},
);

$builder -> add_build_element('conf');
$builder -> create_build_script();

