use 5.000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Config::Directory',
    'VERSION_FROM'	=> 'Directory.pm', # finds $VERSION
    'PREREQ_PM'		=> { 
        'File::Basename'        => 0, 
        'File::Spec'            => 0, 
        'Test::More'            => 0.88,
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Directory.pm', # retrieve abstract from module
       AUTHOR     => 'Gavin Carr <gavin@openfusion.com.au>') : ()),
);
