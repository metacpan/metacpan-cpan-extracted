
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "ElasticSearch command line client.",
  "AUTHOR" => "Mickey Nasriachi <mickey75\@gmail.com>, Kang-min Liu <gugod\@gugod.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-es",
  "EXE_FILES" => [
    "bin/es"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::es",
  "PREREQ_PM" => {
    "ElasticSearch" => 0,
    "File::Slurp" => 0,
    "JSON" => 0,
    "List::MoreUtils" => 0,
    "Pod::Usage" => 0,
    "Term::ANSIColor" => 0,
    "encoding" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.1",
  "test" => {
    "TESTS" => "t/*.t"
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



