use 5.006002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DBIx::BulkLoader::Mysql',
    VERSION_FROM      => 'lib/DBIx/BulkLoader/Mysql.pm', # finds $VERSION
    PREREQ_PM         => {
    		DBI=>1.53
		,DBD::mysql=>2.9006
     }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DBIx/BulkLoader/Mysql.pm', # retrieve abstract from module
       AUTHOR         => 'Michael Shipper') : ()),
);
