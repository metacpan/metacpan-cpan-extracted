use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::NestedSet',
    AUTHOR              => 'SHIRIRU <shiriru-111@hotmail.com>',
    VERSION_FROM        => 'lib/Data/NestedSet.pm',
    ABSTRACT_FROM       => 'lib/Data/NestedSet.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    }
);
