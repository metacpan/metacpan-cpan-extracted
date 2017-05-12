use 5.008009;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Anansi::Actor',
    VERSION_FROM      => 'lib/Anansi/Actor.pm', # finds $VERSION
    PREREQ_PM         => { 'Anansi::Singleton' => 0.01, 'Fcntl' => 1.11, 'File::Find' => 1.20, 'File::Spec::Functions' => 3.40, 'FileHandle' => 2.02 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Anansi/Actor.pm', # retrieve abstract from module
       AUTHOR         => 'Kevin Treleaven <kevin@treleaven.net>') : ()),
);
