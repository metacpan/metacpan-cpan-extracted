
use strict;
use warnings;

 BEGIN { require 5.008; } 

use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Data::Inherited',
                       'DISTNAME' => 'Data-Inherited',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Hierarchy-wide accumulation of list and hash results',
                       'EXE_FILES' => [],
                       'VERSION' => '1.100860',
                       'PREREQ_PM' => {
                                        'Scalar::Util' => '0',
                                        'parent' => '0',
                                        'English' => '0',
                                        'overload' => '0',
                                        'NEXT' => '0.64',
                                        'constant' => '0',
                                        'Carp' => '0',
                                        'Test::More' => '0.88',
                                        'File::Find' => '0',
                                        'File::Temp' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



