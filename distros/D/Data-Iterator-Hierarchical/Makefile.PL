use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::Iterator::Hierarchical',
    AUTHOR              => 'Brian McCauley <nobull@cpan.org>',
    VERSION_FROM        => 'lib/Data/Iterator/Hierarchical.pm',
    ABSTRACT_FROM       => 'lib/Data/Iterator/Hierarchical.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-Iterator-Hierarchical-*' },
);
