use 5.008002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Class::DBI::Loader::Sybase',
    VERSION_FROM      => 'lib/Class/DBI/Loader/Sybase.pm', # finds $VERSION
    PREREQ_PM         => { 
			  Class::DBI::Loader => 0,
			  Class::DBI::Sybase => 0,
			  DBD::Sybase => 1.05,
			 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Class/DBI/Loader/Sybase.pm', # retrieve abstract from module
       AUTHOR         => 'Diab Jerius <djerius@cpan.org>') : ()),
);
