use Module::Build;

Module::Build -> new
(
	module_name		=> 'DBIx::HTML::PopupRadio',
	license			=> 'artistic',
	dist_author		=> 'Ron Savage <ron@savage.net.au>',
	build_requires	=>
	{
		Test::More	=> 0,
		Test::Pod	=> 0,
	},
	requires		=>
	{
		Carp						=> 0,
		HTML::Entities::Interpolate	=> 1.00,
	},
) -> create_build_script();
