
use strict;
use warnings;



use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Catalyst::TraitFor::Controller::Ping',
                       'DISTNAME' => 'Catalyst-TraitFor-Controller-Ping',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Nicholas Perez <nperez@cpan.org>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Provides a ping action for consuming controllers',
                       'EXE_FILES' => [],
                       'VERSION' => '0.001',
                       'PREREQ_PM' => {
                                        'Catalyst::Runtime' => '5.80021'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



