use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Class::DBI::Plugin::DateFormat::Oracle',
    VERSION_FROM      => 'lib/Class/DBI/Plugin/DateFormat/Oracle.pm',
    PREREQ_PM         => {
        'Class::DBI' => 0,
        'Carp'       => 0,
    },
);
