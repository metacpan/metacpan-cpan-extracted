use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::Meow',
    AUTHOR              => 'FOOLISH <foolish@cpan.org>',
    VERSION_FROM        => 'lib/Acme/Meow.pm',
    ABSTRACT_FROM       => 'lib/Acme/Meow.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-Meow-*' },
);
