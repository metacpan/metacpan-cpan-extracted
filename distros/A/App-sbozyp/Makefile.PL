use strict;
use warnings;

use v5.34.0;

use ExtUtils::MakeMaker;

sub MY::postamble {
    return "POD2MAN += -c '' -r sbozyp-\$(VERSION)\n";
}

WriteMakefile(
    NAME         => 'App::sbozyp',
    DISTNAME     => 'App-sbozyp',
    AUTHOR       => 'Nicholas B. Hubbard <nicholashubbard@posteo.net>',
    ABSTRACT     => q(A package manager for Slackware's SlackBuilds.org),
    LICENSE      => 'gpl_3',
    VERSION_FROM => 'bin/sbozyp',
    MIN_PERL_VERSION => '5.34.0',

    EXE_FILES => [
        'bin/sbozyp'
    ],

    MAN3PODS => {},

    # No non-core runtime dependencies
    PREREQ_PM => {},

    META_MERGE => {
        'meta-spec' => { version => 2 },
        prereqs => {
            # Tests are excluded from the dist; their dependencies are for developers.
            develop => {
                requires => {
                    'Test2::V0' => 0,
                    'Test2::Plugin::NoWarnings' => 0,
                    'Capture::Tiny' => 0,
                },
            },
        },
        resources => {
            repository => { url => 'https://github.com/NicholasBHubbard/sbozyp' },
            bugtracker => { web => 'https://github.com/NicholasBHubbard/sbozyp/issues' },
        },
    },
);
