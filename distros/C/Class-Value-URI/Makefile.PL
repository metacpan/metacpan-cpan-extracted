
use strict;
use warnings;

 BEGIN { require 5.008; } 

use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Class::Value::URI',
                       'DISTNAME' => 'Class-Value-URI',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Value class for URIs',
                       'EXE_FILES' => [],
                       'VERSION' => '1.100840',
                       'PREREQ_PM' => {
                                        'Class::Accessor::Complex' => '0',
                                        'Class::Value::Test' => '0',
                                        'Scalar::Util' => '0',
                                        'parent' => '0',
                                        'English' => '0',
                                        'Data::Semantic::URI::TestData::file' => '0',
                                        'Data::Semantic::URI::TestData::ftp' => '0',
                                        'Carp' => '0',
                                        'Test::More' => '0.88',
                                        'Data::Semantic::URI::TestData::fax' => '0',
                                        'File::Find' => '0',
                                        'Class::Value::SemanticAdapter' => '0',
                                        'Test::CompanionClasses' => '0',
                                        'File::Temp' => '0',
                                        'Data::Semantic::URI::TestData::http' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



