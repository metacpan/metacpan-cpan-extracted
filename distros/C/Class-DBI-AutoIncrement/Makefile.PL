use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Class::DBI::AutoIncrement',
    VERSION_FROM      => 'lib/Class/DBI/AutoIncrement.pm', # finds $VERSION
    PREREQ_PM         => {
	Class::Accessor => 0.18,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Class/DBI/AutoIncrement.pm', # retrieve abstract from module
       AUTHOR         => 'Erwan Lemonnier <erwan@cpan.org>') : ()),
);
