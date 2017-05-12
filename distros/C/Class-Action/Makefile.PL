use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::Action',
    AUTHOR              => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM        => 'lib/Class/Action.pm',
    ABSTRACT_FROM       => 'lib/Class/Action.pod',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Carp' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Class-Action-*' },
);
