use ExtUtils::MakeMaker;

WriteMakefile
(
    NAME            => 'DBIx::Procedure::Oracle',
    VERSION_FROM    => 'Oracle.pm',
    (
        $] >= 5.6
        ? (ABSTRACT   => "DBIx::Procedure::Oracle - Call Oracle PL/SQL stored procedures and functions without writing SQL or worrying about data types or bindings.",
           AUTHOR     => 'Mark Southern (mark_southern@merck.com)')
        : ()
    ),
    PREREQ_PM => { 
                    'DBI'         => undef
                   ,'DBD::Oracle' => undef
                 },
    'dist' => {COMPRESS=>'gzip',SUFFIX=>'gz'},
);
