use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CSS::LESSp',
    AUTHOR              => 'Ivan Drinchev <drinchev@gmail.com>',
    VERSION_FROM        => 'lib/CSS/LESSp.pm',
    PL_FILES            => {},
	EXE_FILES			=> [ qw/script\/lessp.pl/ ],
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CSS-Lessp-*' },
);
