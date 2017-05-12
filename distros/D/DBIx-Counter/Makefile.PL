use 5.004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DBIx::Counter',
    VERSION_FROM      => 'lib/DBIx/Counter.pm', # finds $VERSION
    LICENSE           => 'perl',
    PREREQ_PM         => { 
                        DBI => 1.06,
                        Carp => 0.01,
                        Test::More => 0,
                    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DBIx/Counter.pm', # retrieve abstract from module
       AUTHOR         => 'Rhesa Rozendaal <rhesa@cpan.org>') : ()),
);
