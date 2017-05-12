use 5.008003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Bundle::DBWIZ',
    VERSION_FROM      => 'lib/Bundle/DBWIZ.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Bundle/DBWIZ.pm', # retrieve abstract from module
       AUTHOR         => 'Calvin Mah, Simon Fraser University, calvin.mah@gmail.com') : ()),
);
