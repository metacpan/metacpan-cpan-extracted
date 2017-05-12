use Module::Build;

my($builder) = Module::Build -> new
(
	module_name    => 'CGI::Application::Demo::Basic',
	license        => 'artistic',
	dist_author    => 'Ron Savage <ron@savage.net.au>',
	build_requires =>
	{
		Test::More => 0,
		Test::Pod  => 0,
	},
	requires =>
	{
		CGI::Application                      => 0,
		CGI::Application::Plugin::LogDispatch => 0,
		CGI::Application::Plugin::Session     => 0,
		CGI::Simple                           => 0,
		Class::DBI                            => 0,
		Class::DBI::Loader                    => 0,
		Class::DBI::SQLite                    => 0.11,
		Config::Tiny                          => 2.12,
		DBIx::Admin::CreateTable              => 2.06,
		File::Slurp                           => 9999.13,
		FindBin::Real                         => 0,
		Hash::FieldHash                       => 0.10,
		HTML::Template                        => 0,
		Log::Dispatch::DBI                    => 0,
	},
);

$builder -> add_build_element('conf');
$builder -> create_build_script();
