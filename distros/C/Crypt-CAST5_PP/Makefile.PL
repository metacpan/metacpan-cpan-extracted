use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Crypt::CAST5_PP',
    'VERSION_FROM'	=> 'CAST5_PP.pm', # finds $VERSION
    'PREREQ_PM'		=> {"Test::More" => 0.47},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'CAST5_PP.pm', # retrieve abstract from module
       AUTHOR     => 'Bob Mathews <bobmathews@alumni.calpoly.edu>') : ()),
);
