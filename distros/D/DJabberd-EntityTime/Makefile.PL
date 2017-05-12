use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DJabberd::Plugin::EntityTime',
    AUTHOR              => 'Edward Rudd <urkle@outoforder.cc>',
    VERSION_FROM        => 'lib/DJabberd/Plugin/EntityTime.pm',
    ABSTRACT_FROM       => 'lib/DJabberd/Plugin/EntityTime.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'DJabberd' => 0.83,
    },
    DISTNAME		=> 'DJabberd-EntityTime',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DJabberd-Plugin-EntityTime-*' },
);
