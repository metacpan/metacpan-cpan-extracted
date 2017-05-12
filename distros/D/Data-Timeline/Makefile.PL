
use strict;
use warnings;

 BEGIN { require 5.008; } 

use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Data::Timeline',
                       'DISTNAME' => 'Data-Timeline',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Time line represented as an object',
                       'EXE_FILES' => [],
                       'VERSION' => '1.100860',
                       'PREREQ_PM' => {
                                        'Class::Accessor::Complex' => '0',
                                        'Scalar::Util' => '0',
                                        'parent' => '0',
                                        'English' => '0',
                                        'HTML::Table' => '0',
                                        'Text::SimpleTable' => '0',
                                        'Carp' => '0',
                                        'Test::More' => '0.88',
                                        'Class::Accessor::Constructor' => '0',
                                        'File::Find' => '0',
                                        'File::Temp' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



