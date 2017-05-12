
use strict;
use warnings;

 BEGIN { require 5.008; } 

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'App::distfind',
                       'DISTNAME' => 'App-distfind',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>',
                       'BUILD_REQUIRES' => {
                                             'Test::More' => '0.94',
                                             'Scalar::Util' => '0',
                                             'English' => '0',
                                             'File::Temp' => '0',
                                             'Carp' => '0'
                                           },
                       'ABSTRACT' => 'Find Perl module distributions within a directory hierarchy',
                       'EXE_FILES' => [
                                        'bin/distfind'
                                      ],
                       'VERSION' => '1.101400',
                       'PREREQ_PM' => {
                                        'Getopt::Long' => '0',
                                        'Pod::Usage' => '0',
                                        'File::Find' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{BUILD_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.56) };

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



