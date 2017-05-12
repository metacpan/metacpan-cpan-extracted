use Module::Build;

Module::Build -> new
(
 module_name    => 'DBIx::Admin::BackupRestore',
 license        => 'artistic',
 dist_abstract  => 'Back-up all tables in a db to XML, and restore them',
 dist_author    => 'Ron Savage <ron@savage.net.au>',
 build_requires =>
 {
	 Test::More => 0,
 },
 requires =>
 {
	 Carp            => 0,
	 perl            => '5.005_62',
	 XML::Parser     => 0,
	 XML::Records    => 0,
	 XML::TokeParser => 0,
 },
) -> create_build_script();
