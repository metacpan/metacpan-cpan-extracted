use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name		=> 'Convert::Number::Roman',
	dist_version_from	=> 'lib/Convert/Number/Roman.pm',
	dist_author		=> 'Daniel Yacob <dyacob\@cpan.org>',
	dist_abstract		=> "Conversion For Roman Numerals in Perl.",
	release_status		=> 'stable',
	configure_requires	=> { 'Module::Build' => 0.42 },
	requires 		=> {
		'perl'			=> '5.8.0',
	},
	license			=> 'perl',
	add_to_cleanup		=> [ 'Convert-*' ],
	create_makefile_pl	=> 0,  # change to 1 if desired.
	meta_merge		=> {
        	resources => {
			bugtracker => 'https://github.com/dyacob/Convert-Number-Roman/issues',
			repository => 'https://github.com/dyacob/Convert-Number-Roman.git',
			homepage => 'https://github.com/dyacob/Convert-Number-Roman'
		},
		x_authority	=> 'cpan:dyacob'
	}
);

$builder->create_build_script();
