use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Class::Method::Delegate',
    VERSION_FROM      => 'lib/Class/Method/Delegate.pm', # finds $VERSION
    PREREQ_PM         => {
      'Carp' => 0,
      'Scalar::Util' => 0
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Class/Method/Delegate.pm', # retrieve abstract from module
       AUTHOR         => 'Jonathan Taylor <jon@stackhaus.com>') : ()),
);
