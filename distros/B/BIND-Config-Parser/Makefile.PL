use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'BIND::Config::Parser',
	'VERSION_FROM'	=> 'lib/BIND/Config/Parser.pm',
	'PREREQ_PM'	=> {
		'Parse::RecDescent'	=> 0,
	},
	($] >= 5.005 ? (
		'AUTHOR'	=> 'Matt Dainty <matt@bodgit-n-scarper.com>',
	) : () ),
);
