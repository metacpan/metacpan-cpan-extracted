use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DJabberd::Plugin::PrivateStorage',
    AUTHOR              => 'Michael Scherer <misc@zarb.org>',
    VERSION_FROM        => 'lib/DJabberd/Plugin/PrivateStorage.pm',
    ABSTRACT_FROM       => 'lib/DJabberd/Plugin/PrivateStorage.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'DJabberd' => 0,
        'File::Path' => 0,
        'URI::Escape' => 0,
        'File::Slurp' => 0,
        'File::Basename' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DJabberd-Plugin-PrivateStorage-*' },
);
