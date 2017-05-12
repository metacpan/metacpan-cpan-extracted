use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Config::Apt::Sources',
    AUTHOR              => 'Ian Kilgore <iank@cpan.org>',
    VERSION_FROM        => 'lib/Config/Apt/Sources.pm',
    ABSTRACT_FROM       => 'lib/Config/Apt/Sources.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Test::Warn' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Config-Apt-Sources-*' },
);
