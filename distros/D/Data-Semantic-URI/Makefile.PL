
use strict;
use warnings;

 BEGIN { require 5.008; } 

use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Data::Semantic::URI',
                       'DISTNAME' => 'Data-Semantic-URI',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Semantic data classes for URI-related data',
                       'EXE_FILES' => [],
                       'VERSION' => '1.100850',
                       'PREREQ_PM' => {
                                        'Scalar::Util' => '0',
                                        'English' => '0',
                                        'parent' => '0',
                                        'Data::Semantic::Test' => '0',
                                        'constant' => '0',
                                        'Carp' => '0',
                                        'Test::More' => '0.88',
                                        'Test::Differences' => '0',
                                        'File::Find' => '0',
                                        'File::Temp' => '0',
                                        'Test::CompanionClasses' => '0',
                                        'Data::Semantic::RegexpAdapter' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



