use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Class::Protected',
    'VERSION_FROM'	=> 'Protected.pm', # finds $VERSION
    'PREREQ_PM'		=>
    {
       Decision::ACL => 0.02,
       Class::Proxy => 0,
       Class::Maker => 0.5.15,
       IO::Extended => 0.05,

    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Protected.pm', # retrieve abstract from module
       AUTHOR     => 'M. Uenalan, <muenalan@cpan.org>') : ()),
);
