use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Cache::Funky',
    AUTHOR              => 'Masahiro Funakoshi <masap@cpan.org>',
    VERSION_FROM        => 'lib/Cache/Funky.pm',
    ABSTRACT_FROM       => 'lib/Cache/Funky.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'            => 0,
        'version'               => 0,
        'UNIVERSAL::require'    => 0,
        'Class::Accessor::Fast' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Cache-Funky-*' },
);
