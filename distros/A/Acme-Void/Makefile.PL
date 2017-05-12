use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Acme::Void',
    VERSION_FROM      => 'Void.pm', # finds $VERSION
    PREREQ_PM         => {
	Want => 0.01,
	Class::BlackHole => 0.01,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'Void.pm', # retrieve abstract from module
       AUTHOR         => 'Okamoto RYO <ryo@aquahill.net>') : ()),
);
