
use strict;
use warnings;



use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'App::Milter::Limit::Plugin::BerkeleyDB',
                       'DISTNAME' => 'App-Milter-Limit-Plugin-BerkeleyDB',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Michael Schout <mschout@cpan.org>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'BerkeleyDB driver for App::Milter::Limit',
                       'EXE_FILES' => [],
                       'VERSION' => '0.51',
                       'PREREQ_PM' => {
                                        'Module::Signature' => '0',
                                        'Test::More' => '0',
                                        'BerkeleyDB' => '0',
                                        'App::Milter::Limit::Plugin' => '0',
                                        'Class::Accessor' => '0',
                                        'App::Milter::Limit::Log' => '0',
                                        'Socket' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



