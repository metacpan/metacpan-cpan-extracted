use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::Htpasswd::Perishable',
    'VERSION_FROM'	=> 'Perishable.pm', # finds $VERSION
    'PREREQ_PM'		=> { Apache::Htpasswd => 1.5.3 ,
                             Date::Simple => 2.02 ,
                           }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Perishable.pm', # retrieve abstract from module
       AUTHOR     => 'Allen Day <allenday@ucla.edu>') : ()),
);
