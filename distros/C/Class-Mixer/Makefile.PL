use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Class::Mixer',
    VERSION_FROM      => 'lib/Class/Mixer.pm', # finds $VERSION
    PREREQ_PM         => { 'Class::C3' => 0.20,
			   'Test::More' => 0.96,
			 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Class/Mixer.pm', # retrieve abstract from module
       AUTHOR         => 'John Williams <smailliw@gmail.com>') : ()),
);
