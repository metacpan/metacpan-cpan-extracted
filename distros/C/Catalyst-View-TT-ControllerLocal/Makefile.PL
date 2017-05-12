use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Catalyst::View::TT::ControllerLocal',
    AUTHOR              => 'Johan Lindström <johanl@cpan.org>',
    VERSION_FROM        => 'lib/Catalyst/View/TT/ControllerLocal.pm',
    ABSTRACT_FROM       => 'lib/Catalyst/View/TT/ControllerLocal.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        "Catalyst" => 0,
        "Catalyst::View::TT" => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst-View-TT-ControllerLocal-*' },
);
