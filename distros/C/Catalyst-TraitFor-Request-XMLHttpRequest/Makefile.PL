
use strict;
use warnings;



use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Catalyst::TraitFor::Request::XMLHttpRequest',
                       'DISTNAME' => 'Catalyst-TraitFor-Request-XMLHttpRequest',
                       'AUTHOR' => 'Florian Ragwitz <rafl@debian.org>',
                       'ABSTRACT' => 'A request trait for XMLHttpRequest detection support',
                       'EXE_FILES' => [],
                       'VERSION' => '0.01',
                       'LICENSE' => 'perl',
                       'PREREQ_PM' => {
                                        'MooseX::Types::Moose' => '0',
                                        'Test::More' => '0.89',
                                        'namespace::autoclean' => '0',
                                        'ExtUtils::MakeMaker' => '6.11',
                                        'Catalyst' => '5.80',
                                        'CatalystX::RoleApplicator' => '0',
                                        'Moose' => '0'
                                      }
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



