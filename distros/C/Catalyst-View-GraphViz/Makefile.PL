use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Catalyst::View::GraphViz',
    AUTHOR              => 'Johan Lindström <johanl@cpan.org>',
    VERSION_FROM        => 'lib/Catalyst/View/GraphViz.pm',
    ABSTRACT_FROM       => 'lib/Catalyst/View/GraphViz.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        "GraphViz" => 0,
        "Catalyst" => 0,
        "Catalyst::Plugin::SubRequest" => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst-View-GraphViz-*' },
);
