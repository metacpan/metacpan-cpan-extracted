
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Catalyst::ActionRole::MatchRequestMethod',
                       'DISTNAME' => 'Catalyst-ActionRole-MatchRequestMethod',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Florian Ragwitz <rafl@debian.org>',
                       'BUILD_REQUIRES' => {
                                             'Test::More' => '0.89',
                                             'FindBin' => '0',
                                             'Catalyst::Controller::ActionRole' => '0',
                                             'Catalyst::Test' => '0',
                                             'Moose' => '1.03',
                                             'HTTP::Request::Common' => '0'
                                           },
                       'ABSTRACT' => 'Dispatch actions based on HTTP request methods',
                       'EXE_FILES' => [],
                       'VERSION' => '0.03',
                       'PREREQ_PM' => {
                                        'Moose::Role' => '0',
                                        'namespace::autoclean' => '0',
                                        'Catalyst::Runtime' => '5.80',
                                        'Catalyst::Controller::ActionRole' => '0',
                                        'Perl6::Junction' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM}; 
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod}; 
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



