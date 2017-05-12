use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Class::DBI::Loader::DB2',
    VERSION_FROM => 'lib/Class/DBI/Loader/DB2.pm',
    PREREQ_PM    => { 'Class::DBI' => 0.96, 'Class::DBI::DB2' => 0.16, 'Class::DBI::Loader' => 0.02, 'Test::More' => 0.47, 'DBD::DB2' => 0, },
    ( $] >= 5.005
    ? (    # Add these new keywords supported since 5.005
          ABSTRACT_FROM => 'lib/Class/DBI/Loader/DB2.pm',
          AUTHOR        =>
          'Mark Ferris <mark.ferris@geac.com>',
    )
    : () ),
);

