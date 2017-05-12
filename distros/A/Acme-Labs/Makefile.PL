use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::Labs',
    AUTHOR              => 'David Green <plato@cpan.org>',
    VERSION_FROM        => 'lib/Acme/Labs.pm',
    ABSTRACT            => 'The same thing we do every night, narf! poit!',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-Labs-*' },
);
