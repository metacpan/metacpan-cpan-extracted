use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'DBIx::SimpleQuery',
    VERSION_FROM => 'lib/DBIx/SimpleQuery.pm',
    PREREQ_PM => {
        'DBI' => 0,
    },
);
