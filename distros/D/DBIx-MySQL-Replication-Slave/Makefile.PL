
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'DBIx::MySQL::Replication::Slave',
                       'DISTNAME' => 'DBIx-MySQL-Replication-Slave',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Olaf Alders <olaf@wundercounter.com>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Stop, start and monitor your slaves.',
                       'EXE_FILES' => [],
                       'VERSION' => '0.02',
                       'PREREQ_PM' => {
                                        'Data::Dump' => '0',
                                        'DBD::mysql' => '0',
                                        'Moose' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{BUILD_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.56) };

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



