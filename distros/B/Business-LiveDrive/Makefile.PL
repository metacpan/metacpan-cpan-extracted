use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Business::LiveDrive',
    VERSION_FROM      => 'lib/Business/LiveDrive.pm', # finds $VERSION
    PREREQ_PM         => {
        'Class::Accessor' => undef,
        'SOAP::Lite' => undef
        },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Business/LiveDrive.pm', # retrieve abstract from module
       AUTHOR         => 'Jason Clifford <jason@ukfsn.org>') : ()),
);
