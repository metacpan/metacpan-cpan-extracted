use Module::Build;

Module::Build -> new
(
 module_name    => 'CGI::Snapp::Demo::Four',
 license        => 'artistic',
 dist_abstract  => 'A template-free demo of CGI::Snapp using Log::Handler::Plugin::DBI',
 dist_author    => 'Ron Savage <ron@savage.net.au>',
 build_requires =>
 {
 	 Test::More => 0.94,
 	 Test::Pod  => 1.44,
 },
 configure_requires =>
 {
 	 Module::Build => 0.3800,
 },
 requires =>
 {
	 CGI                       => 3.00,
	 CGI::Emulate::PSGI        => 0.14,
	 CGI::Snapp                => 1.03,
	 Config::Plugin::Tiny      => 1.01,
	 File::Spec                => 0.86,
	 File::Temp                => 0.14,
	 Hash::FieldHash           => 0.12,
	 Log::Handler::Plugin::DBI => 1.00,
	 parent                    => 0,
	 # Don't make user install Plack.
	 # Plack                   => 0.9985,
	 # Starman                 => 0.3000,
	 strict                    => 1.03,
	 warnings                  => 1.03,
 },
) -> create_build_script();
