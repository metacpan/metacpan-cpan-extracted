use ExtUtils::MakeMaker;

WriteMakefile(
   NAME          => 'Apache::DBILogin',
   VERSION_FROM  => 'DBILogin.pm',
   PREREQ_PM => { DBI => '0', }
);
