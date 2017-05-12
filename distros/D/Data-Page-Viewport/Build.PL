use Module::Build;

Module::Build -> new
(
	module_name	=> 'Data::Page::Viewport',
	license		=> 'artistic',
	dist_author	=> 'Ron Savage <ron@savage.net.au>',
	build_requires	=>
	{
		Test::More	=> 0,
		Test::Pod	=> 0,
	},
	requires	=>
	{
		Set::Window	=> 0,
	},
) -> create_build_script();
