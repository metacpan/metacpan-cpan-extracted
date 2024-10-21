use strict;
use warnings;

use v5.34.0;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'App::sbozyp',
    DISTNAME     => 'App-sbozyp',
    AUTHOR       => 'Nicholas Hubbard <nicholashubbard@posteo.net>',
    ABSTRACT     => q(a package manager for Slackware's SlackBuilds.org),
    LICENSE      => 'gpl_3',
    VERSION_FROM => 'bin/sbozyp',
    MIN_PERL_VERSION => '5.34.0',

    EXE_FILES => [
        'bin/sbozyp'
    ],

    # No non-core dependencies
    PREREQ_PM => {},

    META_MERGE => {
        resources => {
            repository  => 'https://github.com/NicholasBHubbard/sbozyp',
            bugtracker  => 'https://github.com/NicholasBHubbard/sbozyp/issues',
        },
    },
);
