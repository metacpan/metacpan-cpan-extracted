
use strict;
use warnings;



use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'CatalystX::LeakChecker',
                       'DISTNAME' => 'CatalystX-LeakChecker',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Florian Ragwitz <rafl@debian.org>, Tomas Doran <bobtfish@bobtfish.net>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Debug memory leaks in Catalyst applications',
                       'EXE_FILES' => [],
                       'VERSION' => '0.06',
                       'PREREQ_PM' => {
                                        'PadWalker' => '1.8',
                                        'namespace::autoclean' => '0',
                                        'Devel::Cycle' => '1.11',
                                        'FindBin' => '0',
                                        'B::Deparse' => '0',
                                        'Text::SimpleTable' => '0',
                                        'namespace::clean' => '0.05',
                                        'Test::More' => '0.88',
                                        'MooseX::Types' => '0',
                                        'Catalyst' => '5.8',
                                        'Task::Weaken' => '0',
                                        'Moose' => '0.90'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



