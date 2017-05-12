use 5.008002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Catalyst::Plugin::CRUD',
    VERSION_FROM      => 'lib/Catalyst/Plugin/CRUD.pm', # finds $VERSION
    PREREQ_PM         => { XML::Simple => 2.14, Class::Trigger => 0.08, Jcode => 2.05, Scalar::Util => 1.14 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Catalyst/Plugin/CRUD.pm', # retrieve abstract from module
       AUTHOR         => 'Jun Shimizu <bayside@cpan.org>') : ()),
);
