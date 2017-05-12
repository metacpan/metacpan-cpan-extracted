use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DBIx::HA',
    VERSION_FROM      => 'lib/DBIx/HA.pm', # finds $VERSION
    PREREQ_PM         =>	{ 
    						'DBI' => 1.49,
    						'Sys::SigAction' => 0,
    						}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DBIx/HA.pm', # retrieve abstract from module
       AUTHOR         => 'Henri Asseily <henri@asseily.com>') : ()),
);
