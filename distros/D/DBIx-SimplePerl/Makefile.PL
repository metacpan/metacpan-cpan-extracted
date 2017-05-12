use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DBIx::SimplePerl',
    VERSION_FROM      => 'lib/DBIx/SimplePerl.pm', 
    			# finds $VERSION
    PREREQ_PM         => {Class::Accessor => 0.22, DBI => 1.50 }, 
    			# e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DBIx/SimplePerl.pm', # retrieve abstract from module
       AUTHOR         => 'Joseph Landman <landman@scalableinformatics.com>') : ()),
);
