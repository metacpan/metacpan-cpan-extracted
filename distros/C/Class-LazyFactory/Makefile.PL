use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Class::LazyFactory',
    VERSION_FROM      => 'lib/Class/LazyFactory.pm', # finds $VERSION
    PREREQ_PM         => {
        'Carp'                  => 1.00,
        'Class::Inspector'      => 1.23,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Class/LazyFactory.pm', # retrieve abstract from module
       AUTHOR         => 'Dexter Tad-y <dtady@cpan.org>') : ()),
);
