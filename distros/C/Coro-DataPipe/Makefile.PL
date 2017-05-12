use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Coro::DataPipe',
    VERSION_FROM      => 'lib/Coro/DataPipe.pm', # finds $VERSION
    PREREQ_PM         => {Coro => 6.31}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'cooperative data processing threads', # retrieve abstract from module
       AUTHOR         => 'O. G. Kharchenko <okharch@okharch.com>') : ()),
);
