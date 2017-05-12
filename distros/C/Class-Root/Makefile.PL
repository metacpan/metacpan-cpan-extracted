use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::Root',
    AUTHOR              => 'Evgeny Nifontov <class_root@nifsa.de>',
    VERSION_FROM        => 'lib/Class/Root.pm',
    ABSTRACT_FROM       => 'lib/Class/Root.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Filter::Util::Call' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Class-Root-*' },
);
