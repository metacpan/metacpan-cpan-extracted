use Module::Build;

Module::Build -> new
(
 module_name    => 'Config::Tiny::Ordered',
 license        => 'artistic',
 dist_abstract  => 'Read/Write ordered .ini style files with as little code as possible',
 dist_author    => 'Ron Savage <ron@savage.net.au>',
 build_requires =>
 {
	 Test::More => 0.47,
	 Test::Pod  => 0,
 },
 requires =>
 {
	 Config::Tiny => 2.12,
 },
) -> create_build_script();
