use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Algorithm::SpatialIndex',
    VERSION_FROM      => 'lib/Algorithm/SpatialIndex.pm', # finds $VERSION
    PREREQ_PM         => {
      'Module::Pluggable' => '0',
      'Class::XSAccessor' => '1.05',
      'parent'            => '0',
      'lib'               => '0',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Algorithm/SpatialIndex.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
);
