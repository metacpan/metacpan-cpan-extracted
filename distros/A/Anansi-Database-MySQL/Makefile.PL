use 5.008009;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Anansi::Database::MySQL',
    VERSION_FROM      => 'lib/Anansi/Database/MySQL.pm', # finds $VERSION
    PREREQ_PM         => { 'Anansi::DatabaseComponent' => 0.01 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Anansi/Database/MySQL.pm', # retrieve abstract from module
       AUTHOR         => 'Kevin Treleaven <kevin@treleaven.net>') : ()),
);
