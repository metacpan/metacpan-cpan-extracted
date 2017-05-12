use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'bin/gnuget',
    VERSION_FROM    => 'lib/App/Gnuget.pm',
    ABSTRACT        => 'A tool to grab GNU softwares',
    AUTHOR          => 'Sandro Cazzaniga <kharec@cpan.org>',
    LICENSE         => 'GPLv3+',
    EXE_FILES       => ['bin/gnuget'],
    PREREQ_PM       => {
        "Test::More"          => 0,
        "Net::FTP"            => 0,
        "ExtUtils::MakeMaker" => 0
    }
);
