use Module::Build;

my($builder) = Module::Build -> new
(
	module_name    => 'CGI::Application::Util::Diff',
	license        => 'artistic',
	dist_abstract  => 'Diff 2 directories or files, or run other commands',
	dist_author    => 'Ron Savage <ron@savage.net.au>',
	build_requires =>
	{
		Test::More => 0,
		Test::Pod  => 0,
	},
	requires =>
	{
		Algorithm::Diff             => 0,
		Carp                        => 0,
		CGI                         => 0,
		CGI::Application            => 0,
		CGI::Application::Dispatch  => 0,
		Config::Tiny                => 0,
		DBD::CSV                    => 0, # For default logging.
		DBI                         => 0, # For default logging.
		FCGI::ProcManager           => 0,
		File::stat                  => 0,
		Hash::FieldHash             => 0,
		HTML::Entities::Interpolate => 0,
		HTML::Template              => 0,
		IPC::Capture                => 0,
		Path::Class                 => 0,
		JSON::XS                    => 0,
	},
);

$builder -> add_build_element('conf');
$builder -> create_build_script();
