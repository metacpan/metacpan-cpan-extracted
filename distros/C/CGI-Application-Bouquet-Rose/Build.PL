use Module::Build;

my($builder) = Module::Build -> new
(
	module_name    => 'CGI::Application::Bouquet::Rose',
	license        => 'artistic',
	dist_abstract  => 'Generate a set of CGI::Application-based classes',
	dist_author    => 'Ron Savage <ron@savage.net.au>',
	build_requires =>
	{
		Test::More => 0,
		Test::Pod  => 0,
	},
	requires =>
	{
	 Carp             => 0,
	 Config::IniFiles => 0,
	 File::Copy       => 0,
	 File::Path       => 0,
	 File::Spec       => 0,
	 HTML::Template   => 0,
	},
);

$builder -> add_build_element('conf');
$builder -> create_build_script();
