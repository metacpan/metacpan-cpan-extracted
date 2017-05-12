use 5.008000;
use ExtUtils::MakeMaker;
WriteMakefile
  (
   NAME              => 'Catalyst::Model::SOAP',
   VERSION_FROM      => 'lib/Catalyst/Model/SOAP.pm',
   PREREQ_PM         => { Catalyst::Runtime => 5.7011, XML::Compile::SOAP => 2.14,
                          XML::Compile => 1.06, XML::LibXML => 1.70, Moose => 0.90 },
   ABSTRACT_FROM  => 'lib/Catalyst/Model/SOAP.pm',
   AUTHOR         => 'Daniel Ruoso <daniel@ruoso.com>',
  );
