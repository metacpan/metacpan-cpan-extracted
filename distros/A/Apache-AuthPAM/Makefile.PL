use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::AuthPAM',
    'VERSION_FROM'	=> 'AuthPAM.pm', # finds $VERSION
    'PREREQ_PM'		=> {Authen::PAM => 0.13}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'AuthPAM.pm', # retrieve abstract from module
       AUTHOR     => 'Hector Daniel Cortes Gonzalez <hdcg@cie.unam.mx>') : ()),
);
