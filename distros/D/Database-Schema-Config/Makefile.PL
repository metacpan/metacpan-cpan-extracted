use 5.008007;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Database::Schema::Config',
    VERSION_FROM      => 'lib/Database/Schema/Config.pm', # finds $VERSION
    PREREQ_PM         => {Time::Timestamp => 1.00, Class::ParmList => 1.05}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Database/Schema/Config.pm', # retrieve abstract from module
       AUTHOR         => 'Wes Young <saxguard9-cpan@yahoo.com>') : ()),
);
