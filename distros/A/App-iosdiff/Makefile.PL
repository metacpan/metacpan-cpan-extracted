
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Cisco IOS Config Diff Utility',
  'AUTHOR' => 'Oliver Gorwits <oliver@cpan.org>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'App-iosdiff',
  'EXE_FILES' => [
    'bin/iosdiff'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'App::iosdiff',
  'PREREQ_PM' => {
    'Algorithm::Diff' => '0',
    'Exporter' => '0',
    'File::Slurp' => '0',
    'File::Temp' => '0',
    'List::Util' => '0',
    'Net::DNS' => '0',
    'Regexp::Common' => '0'
  },
  'VERSION' => '1.200001',
  'test' => {
    'TESTS' => ''
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



