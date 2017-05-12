use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CSS::Tiny::Style',
    AUTHOR              => 'Simone Cesano <scesano@cpan.org>',
    VERSION_FROM        => 'lib/CSS/Tiny/Style.pm',
    ABSTRACT_FROM       => 'lib/CSS/Tiny/Style.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CSS-Tiny-Style-*' },
);
