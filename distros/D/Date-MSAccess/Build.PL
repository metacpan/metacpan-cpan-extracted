use Module::Build;

Module::Build -> new
(
	module_name		=> 'Date::MSAccess',
	license			=> 'artistic',
	dist_author		=> 'Ron Savage <ron@savage.net.au>',
	build_requires	=>
	{
		Test::More	=> 0,
		Test::Pod	=> 0,
	},
	requires		=>
	{
		Date::Calc	=> 5.3,
	},
) -> create_build_script();
