use 5.016003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Benchmark::Object',
    VERSION_FROM      => 'lib/Benchmark/Object.pm', # finds $VERSION
    PREREQ_PM         => {'Time::HiRes' => 1.9725}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Benchmark/Object.pm', # retrieve abstract from module
       AUTHOR         => 'Vipin Singh <qwer@cpan.org>') : ()),
);
