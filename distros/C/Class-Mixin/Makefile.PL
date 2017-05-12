use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::Mixin',
    AUTHOR              => 'Stathy G. Touloumis <stathy@stathy.com>',
    VERSION_FROM        => 'lib/Class/Mixin.pm',
    ABSTRACT_FROM       => 'lib/Class/Mixin.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Carp' => 0,
        'Symbol' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Class-Mixin-*' },
);
