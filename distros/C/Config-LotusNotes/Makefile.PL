use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME          => 'Config::LotusNotes',
    VERSION_FROM  => 'lib/Config/LotusNotes.pm',
    ABSTRACT_FROM => 'lib/Config/LotusNotes.pm',
    AUTHOR        => 'Harald Albers <albers@cpan.org>',
    EXE_FILES     => [
        'demo/editnotesini.pl', 
        'demo/FindNotes.pl',
    ],
    PREREQ_PM     => {
        Win32::TieRegistry => 0,
        Config::IniHash    => 0,
        File::HomeDir      => 0,
    },
);
