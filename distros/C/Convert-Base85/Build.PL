use 5.010001;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $build = Module::Build->new(
	module_name => 'Convert::Base85',

	dist_abstract => 'Encoding to and decoding from Base 85 strings',
	dist_author => ['John M. Gamble <jgamble@cpan.org>'],
	dist_version => '1.00',
	dist_name => 'Convert-Base85',
	release_status => 'stable',

	requires => {
		perl=> '5.16.1',
		'Math::Int128' => '0.22',
	},

	configure_requires => {
		'Module::Build' => '0.4224',
	},

	build_requires => {
		'Test::More' => 0
	},

	license => 'perl',
	create_license => 1,
	create_readme => 0,
	create_makefile_pl => 'traditional',
	dynamic_config =>0,
	add_to_cleanup => ['Convert-Base85-*'],

	meta_merge => {
		keywords => [ qw(base-85 encode decode format) ],
		resources => {
			repository => 'git://github.com/jgamble/Convert-Base85.git',
#			repository => {
#				url => 'git://github.com/jgamble/Convert-Base85',
#				web => 'https://github.com/jgamble/Convert-Base85',
#				type => 'git',
#			},
		},
	},

);

$build->create_build_script;
