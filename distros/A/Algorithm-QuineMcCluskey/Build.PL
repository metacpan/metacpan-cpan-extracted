use 5.010001;
use strict;
use warnings FATAL =>'all';
use Module::Build;

my $builder = Module::Build->new(
	module_name => 'Algorithm::QuineMcCluskey',

	dist_abstract => 'Solve sets of Boolean terms with the Quine-McCluskey algorithm',
	dist_author => [q{Darren Kulp <darren@kulp.ch>},
			q{John M. Gamble <jgamble@cpan.org>}],
	dist_version => '0.17',
	release_status => 'stable',

	provides => {
		'Algorithm::QuineMcCluskey' => {
			file => 'lib/Algorithm/QuineMcCluskey.pm',
		},
		'Algorithm::QuineMcCluskey::Util' => {
			file => 'lib/Algorithm/QuineMcCluskey/Util.pm',
		},
		'Algorithm::QuineMcCluskey::Format' => {
			file => 'lib/Algorithm/QuineMcCluskey/Format.pm',
		},
	},

	requires => {
		perl => '5.10.1',
		Moose => '2.16',
		Carp => 0,
		'List::Compare::Functional' => '0.53',
		'List::MoreUtils' => '0.428',
		'Tie::Cycle' => '1.225',
		'namespace::autoclean' => '0.28',
	},

	configure_requires => {
		'Module::Build' => '0.4224',
	},

	build_requires => {
		'Test::More' => 0,
	},

	license => 'perl',
	create_license => 1,
	create_readme => 0,
	create_makefile_pl => 'traditional',
	dynamic_config => 0,
	add_to_cleanup	 => [ 'Algorithm-QuineMcCluskey-*' ],

	meta_merge => {
		keywords => [qw(boolean boolean-algebra quine-mccluskey)],

		resources => {
			repository => 'git://github.com/jgamble/Algorithm-QuineMcCluskey',
#			repository => {
#				url => 'git://github.com/jgamble/Algorithm-QuineMcCluskey',
#				web => 'https://github.com/jgamble/Algorithm-QuineMcCluskey',
#				type => 'git',
#			},
		},
	},
);

$builder->create_build_script;
