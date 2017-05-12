
use strict;
use warnings;

 BEGIN { require 5.008; } 

use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Data::Comparable',
                       'DISTNAME' => 'Data-Comparable',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Present your object for comparison purposes',
                       'EXE_FILES' => [],
                       'VERSION' => '1.100840',
                       'PREREQ_PM' => {
                                        'Scalar::Util' => '0',
                                        'YAML' => '0',
                                        'parent' => '0',
                                        'English' => '0',
                                        'FindBin' => '0',
                                        'Data::Dumper' => '0',
                                        'constant' => '0',
                                        'Carp' => '0',
                                        'Test::More' => '0.88',
                                        'File::Find' => '0',
                                        'File::Temp' => '0',
                                        'UNIVERSAL::require' => '0',
                                        'Data::Inherited' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



