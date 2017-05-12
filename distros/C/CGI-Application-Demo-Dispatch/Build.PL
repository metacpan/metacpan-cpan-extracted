use Module::Build;

Module::Build -> new
(
 module_name    => 'CGI::Application::Demo::Dispatch',
 license        => 'artistic',
 dist_abstract  => 'Help study usage of CGI::Application::Dispatch',
 dist_author    => 'Ron Savage <ron@savage.net.au>',
 build_requires =>
 {
	 Test::More => 0.96,
	 Test::Pod  => 1.44,
 },
 configure_requires =>
 {
	 Module::Build => 0.3800,
 },
 requires =>
 {
	 CGI                        => 3.52,
	 CGI::Application           => 4.31,
	 CGI::Application::Dispatch => 2.18,
	 FCGI::ProcManager          => 0.19,
	 HTML::Template             => 2.9,
 },
) -> create_build_script();
