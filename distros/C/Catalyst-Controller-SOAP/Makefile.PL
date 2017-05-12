use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Catalyst::Controller::SOAP',
    VERSION_FROM      => 'lib/Catalyst/Controller/SOAP.pm', # finds $VERSION
    PREREQ_PM         => { Catalyst::Runtime => 5.90017, XML::LibXML => 0, MRO::Compat => 0,
                           XML::Compile::SOAP => 2.35, Moose => 0.90,
                          },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Catalyst/Controller/SOAP.pm', # retrieve abstract from module
       AUTHOR         => 'Daniel Ruoso <daniel@ruoso.com>') : ()),
);
