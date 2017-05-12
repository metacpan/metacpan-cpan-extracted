
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'send yourself a reminder',
  'AUTHOR' => 'David F. Houghton <dfhoughton@gmail.com>',
  'BUILD_REQUIRES' => {
    'Test::Fatal' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'App-Nag',
  'EXE_FILES' => [
    'bin/nag',
    'bin/nag'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'App::Nag',
  'PREREQ_PM' => {
    'DateTime' => '0',
    'DateTime::TimeZone' => '0',
    'File::Temp' => '0',
    'Getopt::Long::Descriptive' => '0',
    'Gtk2' => '0',
    'Gtk2::Notify' => '0',
    'Modern::Perl' => '0',
    'constant' => '0'
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



