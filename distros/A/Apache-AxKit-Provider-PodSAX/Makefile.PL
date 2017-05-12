use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::AxKit::Provider::PodSAX',
    'VERSION_FROM'	=> 'PodSAX.pm', # finds $VERSION
    'PREREQ_PM'		=> {Pod::SAX}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'PodSAX.pm', # retrieve abstract from module
       AUTHOR     => 'Kip Hampton <khampton#totalcinema.com>') : ()),
);
