
use strict;
use warnings;

 BEGIN { require 5.008_001; } 

use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'CPAN::Command',
                       'DISTNAME' => 'CPAN-Command',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Load CPAN command plugins',
                       'EXE_FILES' => [],
                       'VERSION' => '1.100840',
                       'PREREQ_PM' => {
                                        'Module::Pluggable' => '0',
                                        'Scalar::Util' => '0',
                                        'URI' => '0',
                                        'English' => '0',
                                        'Carp' => '0',
                                        'Test::More' => '0.88',
                                        'Regexp::Common' => '0',
                                        'File::Find' => '0',
                                        'File::Temp' => '0',
                                        'CPAN' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



