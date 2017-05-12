use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'BBS::UserInfo::Wretch',
    AUTHOR              => 'Gea-Suan Lin <gslin@gslin.org>',
    VERSION_FROM        => 'Wretch.pm',
    ABSTRACT_FROM       => 'Wretch.pm',
    PL_FILES            => {},
    PREREQ_PM => {
	'Carp' => 0,
	'Expect' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'BBS-UserInfo-Wretch-*' },
);
