use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'AnnoCPAN::Perldoc',
    'VERSION_FROM'	=> 'lib/AnnoCPAN/Perldoc.pm',
    'EXE_FILES'         => [qw( annopod )],
    'PREREQ_PM'		=> {
        DBI          => 0,
        DBD::SQLite  => 1.0,
        IO::String   => 0,
        Digest::MD5  => 0,
        Pod::Perldoc => 3.14,
    },
);

