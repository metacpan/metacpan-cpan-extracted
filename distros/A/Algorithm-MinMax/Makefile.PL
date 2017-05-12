use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Algorithm::MinMax',
    'VERSION_FROM'	=> 'MinMax.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'MinMax.pm', # retrieve abstract from module
       AUTHOR     => 'A. U. Thor <a.u.thor@a.galaxy.far.far.away>') : ()),
);
