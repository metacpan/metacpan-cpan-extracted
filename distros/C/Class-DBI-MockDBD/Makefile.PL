use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Class::DBI::MockDBD',
    VERSION_FROM      => 'lib/Class/DBI/MockDBD.pm',
    PREREQ_PM         => {
			  DBD::Mock => 1.34, 
			  Class::DBI => 3.0,
			  Class::Data::Inheritable =>  0.04,
			 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'aaron trevena <aaron.trevena@gmail.com>') : ()),
);
