use Module::Build;
my $build = new Module::Build (
	module_name => 'Crypt::Pwsafe',
	dist_author => 'Shufeng Tan <shufengtan@gmail.com>',
	license => 'perl',
	requires => {
		'perl'		 => '5.8',
		'Crypt::Twofish' => '0.1',
		'Digest::SHA'	 => '0.1',
		'Term::ReadKey'  => '0.1',
	},
);
$build->create_build_script;
