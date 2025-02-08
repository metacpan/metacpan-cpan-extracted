use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name		=> 'Convert::CEGH',
	dist_version_from	=> 'lib/Convert/CEGH.pm',
	dist_author		=> 'Daniel Yacob <dyacob\@cpan.org>',
	dist_abstract		=> "Gematria and Transliteration for Coptic, Ethiopic, Greek and Hebrew.",
	release_status		=> 'stable',
	configure_requires	=> { 'Module::Build' => 0.42 },
	requires 		=> {
		'perl'			=> '5.6.1',
		'Regexp::Ethiopic'	=> '0.10'
	},
	license			=> 'perl',
	add_to_cleanup		=> [ 'Convert-CEGH-*' ],
	create_makefile_pl	=> 0,  # change to 1 if desired.
	meta_merge		=> {
        	resources => {
			bugtracker => 'https://github.com/dyacob/Convert-CEGH/issues',
			repository => 'https://github.com/dyacob/Convert-CEGH.git',
			homepage => 'https://github.com/dyacob/Convert-CEGH'
		},
	},
	x_authority	=> 'cpan:dyacob'
);

$builder->create_build_script();
