use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'AutoXS',
    VERSION_FROM      => 'lib/AutoXS.pm', # finds $VERSION
    PREREQ_PM         => {
      'B::Utils' => '0.05_06',
      'B::Generate' => '0',
      'Class::XSAccessor' => '0.02',
    }, # e.g., Module::Name => 1.1
    LICENSE => 'perl',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/AutoXS.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
);

