use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::Unique',
    AUTHOR              => 'Mike Friedman <friedo@friedo.com>',
    VERSION_FROM        => 'lib/Class/Unique.pm',
    ABSTRACT_FROM       => 'lib/Class/Unique.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Class-Unique-*' },
);
