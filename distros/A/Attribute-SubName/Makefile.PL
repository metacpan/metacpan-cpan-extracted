
use strict;
use warnings;

 BEGIN { require 5.006; } 

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Attribute::SubName',
                       'DISTNAME' => 'Attribute-SubName',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>',
                       'BUILD_REQUIRES' => {
                                             'Test::More' => '0.94',
                                             'Scalar::Util' => '0',
                                             'English' => '0',
                                             'File::Find' => '0',
                                             'File::Temp' => '0',
                                             'Carp' => '0'
                                           },
                       'ABSTRACT' => 'Naming anonymous subroutines via attributes',
                       'EXE_FILES' => [],
                       'VERSION' => '1.101420',
                       'PREREQ_PM' => {
                                        'parent' => '0',
                                        'Attribute::Handlers' => '0',
                                        'Sub::Name' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{BUILD_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.56) };

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



