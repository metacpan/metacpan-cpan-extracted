use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Config::Cascade',
    AUTHOR              => 'Bill Nash <billn@billn.net>',
    VERSION_FROM        => 'lib/Config/Cascade.pm',
    ABSTRACT_FROM       => 'lib/Config/Cascade.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Regexp::Common' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Config-Cascade-*' },
);
