use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::DBI::Relationship::HasVariant',
    AUTHOR              => 'Ricardo Signes <rjbs@cpan.org>',
    VERSION_FROM        => 'lib/Class/DBI/Relationship/HasVariant.pm',
    ABSTRACT_FROM       => 'lib/Class/DBI/Relationship/HasVariant.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Class::DBI' => 0.96,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Class-DBI-Relationship-HasVariant-* t/db/variants.db' },
);
