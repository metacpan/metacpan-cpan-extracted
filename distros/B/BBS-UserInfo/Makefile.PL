use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'BBS::UserInfo',
    AUTHOR              => 'Gea-Suan Lin <gslin@gslin.org>',
    VERSION_FROM        => 'UserInfo.pm',
    ABSTRACT_FROM       => 'UserInfo.pm',
    PL_FILES            => {},
    PREREQ_PM => {
	'Carp' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'BBS-UserInfo-*' },
);
