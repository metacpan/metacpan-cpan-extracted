use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DateTime::Format::XSD',
    VERSION_FROM      => 'lib/DateTime/Format/XSD.pm', # finds $VERSION
    PREREQ_PM         => { DateTime::Format::ISO8601 => 0 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DateTime/Format/XSD.pm', # retrieve abstract from module
       AUTHOR         => 'Daniel Ruoso <daniel@ruoso.com>') : ()),
);
