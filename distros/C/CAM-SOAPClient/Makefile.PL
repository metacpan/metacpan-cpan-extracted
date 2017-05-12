#!perl -w
use warnings;
use strict;
use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME'		=> 'CAM::SOAPClient',
              'VERSION_FROM'	=> 'lib/CAM/SOAPClient.pm',
              'PREREQ_PM'		=> {
                 'SOAP::Lite'      => 0.55,
              },
              'PL_FILES'        => {},
              ($] >= 5.005 ?
               (ABSTRACT_FROM => 'lib/CAM/SOAPClient.pm',
                AUTHOR     => 'Clotho Advanced Media Inc. <cpan@clotho.com>') : ()),
              );
