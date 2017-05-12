#!perl -w
use warnings;
use strict;
use Module::Build;
Module::Build->new(
                   module_name => 'CAM::SOAPClient',
                   license => 'perl',
                   requires => {
                      'SOAP::Lite'               => '0.55',
                   },
                   recommends => {
                      'CAM::SOAPApp'             => '1.03', # needed for advanced test
                   },
                   build_requires => {
                      'Test::More'               => '0.01',
                      'IO::Socket'               => '1.00',
                   },
                   )->create_build_script;
