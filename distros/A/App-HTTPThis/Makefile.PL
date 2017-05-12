
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Export the current directory over HTTP',
  'AUTHOR' => 'Pedro Melo <melo@cpan.org>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'App-HTTPThis',
  'EXE_FILES' => [
    'bin/http_this'
  ],
  'LICENSE' => 'artistic_2',
  'NAME' => 'App::HTTPThis',
  'PREREQ_PM' => {
    'Getopt::Long' => '0',
    'Net::Rendezvous::Publish' => '0.04',
    'Plack::App::Directory' => '0',
    'Plack::Runner' => '0',
    'Pod::Usage' => '0'
  },
  'VERSION' => '0.002',
  'test' => {
    'TESTS' => 't/*.t'
  }
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



