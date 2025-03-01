use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name		=> 'Convert::Braille',
	dist_version_from	=> 'lib/Convert/Braille.pm',
	dist_author		=> 'Daniel Yacob <dyacob\@cpan.org>',
	dist_abstract		=> "Conversion between Braille encodings.",
	release_status		=> 'stable',
	configure_requires	=> { 'Module::Build' => 0.42 },
	requires 		=> {
		'perl'				=> '5.6.1',
		'Convert::Number::Ethiopic'	=> '0.14'
	},
	license			=> 'perl',
	add_to_cleanup		=> [ 'Convert-Braille-*' ],
	create_makefile_pl	=> 0,  # change to 1 if desired.
	meta_merge		=> {
        	resources => {
			bugtracker => 'https://github.com/dyacob/Convert-Braille/issues',
			repository => 'https://github.com/dyacob/Convert-Braille.git',
			homepage => 'https://github.com/dyacob/Convert-Braille'
		},
		x_authority	=> 'cpan:dyacob'
	},
);

$builder->create_build_script();
