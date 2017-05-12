use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DBIx::SQL::Abstract',
    VERSION_FROM      => 'lib/DBIx/SQL/Abstract.pm', # finds $VERSION
    PREREQ_PM         => { DBI => 0,  SQL::Abstract => 1.1}, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DBIx/SQL/Abstract.pm', 
       AUTHOR         => 'Alejandro Juarez <alex@bsdcoders.org>') : ()),
);
