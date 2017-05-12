use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DJabberd::Plugin::JabberIqVersion',
    AUTHOR              => 'Michael Scherer <misc@zarb.org>',
    VERSION_FROM        => 'lib/DJabberd/Plugin/JabberIqVersion.pm',
    ABSTRACT_FROM       => 'lib/DJabberd/Plugin/JabberIqVersion.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'DJabberd' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DJabberd-Plugin-JabberIqVersion-*' },
);
