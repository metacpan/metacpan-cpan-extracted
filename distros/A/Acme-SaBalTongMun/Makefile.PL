
use strict;
use warnings;



use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Acme::SaBalTongMun',
                       'DISTNAME' => 'Acme-SaBalTongMun',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Keedi Kim - 김도형 <keedi at cpan.org>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'make a round robin (사발통문, 沙鉢通文)',
                       'EXE_FILES' => [],
                       'VERSION' => '1.100830',
                       'PREREQ_PM' => {
                                        'List::Util' => '0',
                                        'Test::More' => '0',
                                        'namespace::autoclean' => '0',
                                        'GD' => '0',
                                        'common::sense' => '0',
                                        'Moose' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



