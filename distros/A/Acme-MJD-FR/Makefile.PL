use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		=> "Acme::MJD::FR",
    AUTHOR		=> 'Rafael Garcia-Suarez <rgarciasuarez@gmail.com>',
    VERSION_FROM	=> "lib/Acme/MJD/FR.pm",
    LICENSE		=> 'perl',
    PREREQ_PM		=> {
	'Test::More'	=> 0,
    },
);
