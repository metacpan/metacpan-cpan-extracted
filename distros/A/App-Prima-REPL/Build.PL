use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
	module_name => 'App::Prima::REPL',
	license  => 'perl',
	configure_requires => {
		# meta_merge was added in v 0.28:
		'Module::Build' => 0.28,
	},
	requires => {
		Prima	=> '1.33',
	},
	recommends => {
		'PDL::Graphics::Prima' => '0',
		'PDL' => '0',
	},
	meta_merge => {
		resources => {
			repository
				=> 'http://github.com/run4flat/App-Prima-REPL',
#				=> {
#					web => 'http://github.com/run4flat/App-Prima-REPL',
#					url => 'git://github.com/run4flat/App-Prima-REPL',
#					type => 'git',
#				},
			bugtracker
				=> 'http://github.com/run4flat/App-Prima-REPL/issues',
#				=> {
#					web => 'http://github.com/run4flat/App-Prima-REPL/issues',
#				},
		},
	},
);

$build->create_build_script;
