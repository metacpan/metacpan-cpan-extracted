use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DJabberd::Plugin::Ping',
    AUTHOR              => 'Michael Scherer <misc@zarb.org>',
    VERSION_FROM        => 'lib/DJabberd/Plugin/Ping.pm',
    ABSTRACT_FROM       => 'lib/DJabberd/Plugin/Ping.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'DJabberd' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DJabberd-Plugin-Ping-*' },
);
