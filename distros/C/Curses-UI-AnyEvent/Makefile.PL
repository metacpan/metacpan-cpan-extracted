use strict;

use ExtUtils::MakeMaker;


my %args = (
    NAME => 'Curses::UI::AnyEvent',
    VERSION_FROM => 'lib/Curses/UI/AnyEvent.pm',
    PREREQ_PM => {
      'Curses::UI' => 0,
      'AnyEvent' => 0,
    },
    LIBS => [],
    DEFINE => '',
    LICENSE => 'perl',
    dist => {
      PREOP => 'pod2text $(VERSION_FROM) > $(DISTVNAME)/README',
    },
    META_MERGE => {
      resources => {
        repository => 'git://github.com/hoytech/Curses-UI-AnyEvent.git',
        bugtracker => 'https://github.com/hoytech/Curses-UI-AnyEvent/issues',
      },
    },
);

WriteMakefile(%args);
