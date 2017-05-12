use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Acme::Monkey',
    AUTHOR          => 'Aran Clary Deltac <bluefeet@cpan.org>',
    VERSION_FROM    => 'lib/Acme/Monkey.pm',
    ABSTRACT_FROM   => 'lib/Acme/Monkey.pm',
    PREREQ_PM => {
        'Test::More' => 0,
        'File::Find' => 0,
        'Term::ANSIColor' => 0,
        'Time::HiRes' => 0,
        'Term::ReadKey' => 0,
        'Term::Screen' => 0,
        'Moose' => 0,
    },
    EXE_FILES => [
        'bin/monkey_ship.pl',
        'bin/monkey_life.pl',
    ],
);

