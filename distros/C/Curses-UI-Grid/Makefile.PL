
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Curses::UI::Grid',
    VERSION_FROM => 'lib/Curses/UI/Grid.pm',
    DISTNAME     => 'Curses-UI-Grid',
    PREREQ_PM    => { 
        'Curses::UI'       => 0,
    },

    dist         => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    clean        => { FILES => 'MANIFEST.bak' },
);
