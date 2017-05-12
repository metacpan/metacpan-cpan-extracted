use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DateTime::Format::WindowsFileTime',
    VERSION_FROM      => 'lib/DateTime/Format/WindowsFileTime.pm', # finds $VERSION
    PREREQ_PM         => {'DateTime' => '0.25', 'Math::BigInt' => '1.70'}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DateTime/Format/WindowsFileTime.pm', # retrieve abstract from module
       AUTHOR         => 'Jim <jg.perl@thegarvin.com>') : ()),
);
