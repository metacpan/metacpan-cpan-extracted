use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Class::DBI::Plugin::TimePiece::Oracle',
    VERSION_FROM      => 'lib/Class/DBI/Plugin/TimePiece/Oracle.pm',
    PREREQ_PM         => {
        'Class::DBI::Plugin::DateFormat::Oracle' => 0,
        'Carp'                => 0,
    },
);
