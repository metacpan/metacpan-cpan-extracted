use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name		=> 'Convert::Number::Digits',
	dist_version_from	=> 'lib/Convert/Number/Digits.pm',
	dist_author		=> 'Daniel Yacob <dyacob\@cpan.org>',
	dist_abstract		=> "Convert Digits Between the Scripts of Unicode.",
	release_status		=> 'stable',
	configure_requires	=> { 'Module::Build' => 0.42 },
	requires 		=> {
		'perl'			=> '5.6.1',
	},
	license			=> 'perl',
	add_to_cleanup		=> [ 'Convert-*' ],
	create_makefile_pl	=> 0,  # change to 1 if desired.
	meta_merge		=> {
        	resources => {
			bugtracker => 'https://github.com/dyacob/Convert-Number-Digits/issues',
			repository => 'https://github.com/dyacob/Convert-Number-Digits.git',
			homepage => 'https://github.com/dyacob/Convert-Number-Digits'
		},
		x_authority	=> 'cpan:dyacob'
	}
);

$builder->create_build_script();
