
use strict;
use warnings;

 BEGIN { require 5.008; } 

use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Data::Domain::SemanticAdapter',
                       'DISTNAME' => 'Data-Domain-SemanticAdapter',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Adapter for Data::Semantic objects',
                       'EXE_FILES' => [],
                       'VERSION' => '1.100840',
                       'PREREQ_PM' => {
                                        'Class::Accessor::Complex' => '0',
                                        'Scalar::Util' => '0',
                                        'parent' => '0',
                                        'English' => '0',
                                        'Data::Semantic::Test' => '0',
                                        'constant' => '0',
                                        'Data::Domain' => '0',
                                        'Hash::Rename' => '0',
                                        'Carp' => '0',
                                        'Test::More' => '0.88',
                                        'File::Find' => '0',
                                        'File::Temp' => '0',
                                        'Data::Inherited' => '0',
                                        'UNIVERSAL::require' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



