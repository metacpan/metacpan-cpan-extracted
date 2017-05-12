use Module::Build;

my($builder) = Module::Build -> new
(
	module_name    => 'CGI::Application::Demo::Ajax',
	license        => 'artistic',
	dist_abstract  => 'A search engine using CGI::Application, AJAX and JSON',
	dist_author    => 'Ron Savage <ron@savage.net.au>',
	build_requires =>
	{
		Test::More => 0,
		Test::Pod  => 0,
	},
	requires =>
	{
		Carp             => 0,
		CGI::Application => 0,
		Config::Tiny     => 0,
		DBD::CSV         => 0,
		DBI              => 0,
		HTML::Template   => 0,
		JSON::XS         => 0,
	},
);

$builder -> add_build_element('conf');
$builder -> create_build_script();
