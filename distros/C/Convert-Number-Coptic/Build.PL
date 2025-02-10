use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name		=> 'Convert::Number::Coptic',
	dist_version_from	=> 'lib/Convert/Number/Coptic.pm',
	dist_author		=> 'Daniel Yacob <dyacob\@cpan.org>',
	dist_abstract		=> "Conversion for Coptic Numerals in Perl.",
	release_status		=> 'stable',
	configure_requires	=> { 'Module::Build' => 0.42 },
	requires 		=> {
		'perl'			=> '5.6.1',
		'Regexp::Ethiopic'	=> '0.10'
	},
	license			=> 'perl',
	add_to_cleanup		=> [ 'Convert-*' ],
	create_makefile_pl	=> 0,  # change to 1 if desired.
	meta_merge		=> {
        	resources => {
			bugtracker => 'https://github.com/dyacob/Convert-Number-Coptic/issues',
			repository => 'https://github.com/dyacob/Convert-Number-Coptic.git',
			homepage => 'https://github.com/dyacob/Convert-Number-Coptic'
		},
		x_authority	=> 'cpan:dyacob'
	}
);

$builder->create_build_script();
