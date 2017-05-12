
use strict;
use warnings;

 BEGIN { require 5.010; } 

use ExtUtils::MakeMaker 6.31;

use File::ShareDir::Install;
install_share "share";


my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Bot::Training::MegaHAL',
                       'DISTNAME' => 'Bot-Training-MegaHAL',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31',
                                                 'File::ShareDir::Install' => '0.03'
                                               },
                       'AUTHOR' => 'Ævar Arnfjörð Bjarmason <avar@cpan.org>',
                       'BUILD_REQUIRES' => {
                                             'Test::More' => '0',
                                             'File::Find' => '0',
                                             'File::Temp' => '0'
                                           },
                       'ABSTRACT' => 'Provide F<megahal.trn> via L<Bot::Training>',
                       'EXE_FILES' => [],
                       'VERSION' => '0.02',
                       'PREREQ_PM' => {
                                        'Any::Moose' => '0',
                                        'Bot::Training::Plugin' => '0'
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

package
MY;
use File::ShareDir::Install qw(postamble);


