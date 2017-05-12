use Module::Build;

Module::Build -> new
(
 module_name    => 'CGI::Session::ExpireSessions',
 license        => 'artistic_2',
 dist_abstract  => 'Expires CGI::Session db-based and file-based sessions',
 dist_author    => 'Ron Savage <ron@savage.net.au>',
 build_requires =>
 {
	 Test::More=> 0,
#	 Test::Pod  => 1.45, # Make it optional. See t/pod.t
 },
 configure_requires =>
 {
	 Module::Build => 0.3800,
 },
 requires =>
 {
	 Carp         => 0,
	 CGI::Session => 4.14,
	 File::Spec   => 0,
 },
) -> create_build_script();
