use Module::Build;

Module::Build -> new
(
	module_name    => 'Data::PABX::ParseLex',
	license        => 'artistic_2',
	dist_abstract  => 'Parse output of /lex a e/ command for the iSDC PABX',
	dist_author    => 'Ron Savage <ron@savage.net.au>',
	build_requires =>
	{
		Test::More => 0,
#		Test::Pod  => 1.45, # Make it optional. See t/pod.t
	},
	configure_requires =>
	{
		Module::Build => 0.3800,
	},
	requires =>
	{
		Carp         => 0,
		Data::Dumper => 2.139,
		strict       => 0,
		warnings     => 0,
	},
) -> create_build_script();
