use Module::Build;

Module::Build -> new
(
	module_name    => 'CGI::Session::Driver::odbc',
	license        => 'artistic',
	dist_author    => 'Ron Savage <ron@savage.net.au>',
	build_requires =>
	{
	 Test::More => 0.94,
	 Test::Pod  => 1.41,
	},
	requires =>
	{
		Carp         => 0,
		CGI::Session => '4.42',
		DBI          => 1.609,
	},
) -> create_build_script();
