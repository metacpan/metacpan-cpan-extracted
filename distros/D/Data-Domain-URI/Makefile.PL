
use strict;
use warnings;

 BEGIN { require 5.008; } 

use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Data::Domain::URI',
                       'DISTNAME' => 'Data-Domain-URI',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Data domain classes for URIs',
                       'EXE_FILES' => [],
                       'VERSION' => '1.100850',
                       'PREREQ_PM' => {
                                        'Scalar::Util' => '0',
                                        'Test::CompanionClasses::Base' => '0',
                                        'Data::Semantic::URI::TestData::fax' => '0',
                                        'File::Find' => '0',
                                        'Test::CompanionClasses' => '0',
                                        'English' => '0',
                                        'parent' => '0',
                                        'Data::Semantic::URI::TestData::file' => '0',
                                        'constant' => '0',
                                        'Data::Domain::SemanticAdapter::Test' => '0',
                                        'Exporter' => '0',
                                        'Data::Semantic::URI::TestData::ftp' => '0',
                                        'Carp' => '0',
                                        'Test::More' => '0.88',
                                        'Data::Domain::SemanticAdapter' => '0',
                                        'File::Temp' => '0',
                                        'Data::Semantic::URI::TestData::http' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



