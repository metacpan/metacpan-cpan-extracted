use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Chess::Rep',
    AUTHOR              => 'Mihai Bazon <mihai.bazon@gmail.com>',
    VERSION_FROM        => 'lib/Chess/Rep.pm',
    ABSTRACT_FROM       => 'lib/Chess/Rep.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Chess-Rep-*' },
);
