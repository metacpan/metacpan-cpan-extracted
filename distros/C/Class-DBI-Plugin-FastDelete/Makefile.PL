use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Class::DBI::Plugin::FastDelete',
    VERSION_FROM => 'lib/Class/DBI/Plugin/FastDelete.pm',
    PREREQ_PM    => {
        'SQL::Abstract' => 0,
        'Class::DBI'    => 0,
    },
);
