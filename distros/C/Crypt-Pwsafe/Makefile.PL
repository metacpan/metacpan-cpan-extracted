use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Crypt::Pwsafe',
    AUTHOR              => 'Shufeng Tan <shufengtan@gmail.com>',
    VERSION_FROM        => 'lib/Crypt/Pwsafe.pm',
    ABSTRACT_FROM       => 'lib/Crypt/Pwsafe.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Crypt::Twofish' => 0.1,
	'Digest::SHA' => 0.1,
	'Term::ReadKey' => 0.1,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Crypt-Pwsafe-*' },
);
