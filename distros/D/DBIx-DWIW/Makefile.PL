use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'DBIx::DWIW',
    'VERSION_FROM'	=> 'lib/DBIx/DWIW.pm', # finds $VERSION
    'PREREQ_PM'		=> { DBI => 1.12, 'Time::HiRes' => 0.01, 'DBD::mysql' => 2.00},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/DBIx/DWIW.pm', # retrieve abstract from module
       AUTHOR     => 'Jeremy Zawodny <Jeremy@Zawodny.com>') : ()),
);
