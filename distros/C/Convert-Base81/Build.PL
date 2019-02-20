use Module::Build;
use strict;
use warnings;

my $build = Module::Build->new(
	module_name => 'Convert::Base81',

	dist_abstract => 'Encoding to and decoding from Base 81 strings',
	dist_author => ['John M. Gamble <jgamble@cpan.org>'],
	dist_version => '1.02',
	dist_name => 'Convert-Base81',

	requires => {
		perl => '5.16.1',
		'Math::Int128' => '0.22',
	},

	configure_requires => {
		'Module::Build' => '0.4',
	},

	build_requires => {
		'Test::More' => 0
	},

	license => 'perl',
	create_license => 1,
	create_readme => 0,
	create_makefile_pl => 'traditional',
	dynamic_config =>0,

	meta_merge => {
		keywords => [ qw(base-81 encode decode format) ],
		resources => {
			repository => 'git://github.com/jgamble/Convert-Base81.git',
#			repository => {
#				url => 'git://github.com/jgamble/Convert-Base81',
#				web => 'https://github.com/jgamble/Convert-Base81',
#				type => 'git',
#			},
		},
	},

);

$build->create_build_script;
