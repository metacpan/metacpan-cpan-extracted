use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Class::PINT',
    VERSION_FROM      => 'lib/Class/PINT.pm', # finds $VERSION
    PREREQ_PM         => {
			  Class::DBI=>0.96,
			  Class::DBI::AbstractSearch=>0.05,
			  URI::Escape=> 3,
			  Class::DBI::Relationship::IsA => 0.02,
			  Test::More => 0,
			 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'Aaron Trevena <teejay@droogs.org>') : ()),
);
