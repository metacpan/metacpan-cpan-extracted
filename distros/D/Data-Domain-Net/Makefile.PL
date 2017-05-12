
use strict;
use warnings;

 BEGIN { require 5.008; } 

use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Data::Domain::Net',
                       'DISTNAME' => 'Data-Domain-Net',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Data domain classes for IP addresses',
                       'EXE_FILES' => [],
                       'VERSION' => '1.100840',
                       'PREREQ_PM' => {
                                        'Scalar::Util' => '0',
                                        'parent' => '0',
                                        'English' => '0',
                                        'constant' => '0',
                                        'Data::Semantic::Net::IPAddress::TestData::IPv4' => '0',
                                        'Data::Domain::SemanticAdapter::Test' => '0',
                                        'Exporter' => '0',
                                        'Carp' => '0',
                                        'Test::More' => '0.88',
                                        'Data::Domain::SemanticAdapter' => '0',
                                        'File::Find' => '0',
                                        'Data::Semantic::Net::IPAddress::TestData::IPv6' => '0',
                                        'Test::CompanionClasses' => '0',
                                        'File::Temp' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



