use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::IPV4::Range::Parse',
    VERSION_FROM      => 'lib/Data/IPV4/Range/Parse.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Data/IPV4/Range/Parse.pod', # retrieve abstract from module
       AUTHOR         => 'Michael Shipper') : ()),
);
