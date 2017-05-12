use Module::Build;

Module::Build -> new
(
 module_name    => 'Config::Plugin::Tiny',
 license        => 'artistic',
 dist_abstract  => 'A plugin which uses Config::Tiny',
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
	 Carp         => 1.01,
	 Config::Tiny => 2.14,
	 strict       => 1.03,
	 vars         => 1.01,
	 warnings     => 1.03,
 },
) -> create_build_script();
