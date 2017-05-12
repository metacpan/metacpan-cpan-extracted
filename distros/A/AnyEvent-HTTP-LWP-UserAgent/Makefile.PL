
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "LWP::UserAgent interface but works using AnyEvent::HTTP",
  "AUTHOR" => "Yury Zavarin <yury.zavarin\@gmail.com>",
  "BUILD_REQUIRES" => {
    "File::Temp" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "AnyEvent-HTTP-LWP-UserAgent",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "AnyEvent::HTTP::LWP::UserAgent",
  "PREREQ_PM" => {
    "AnyEvent" => 5,
    "AnyEvent::HTTP" => "2.1",
    "HTTP::Headers::Util" => 0,
    "HTTP::Request::Common" => 0,
    "HTTP::Response" => 0,
    "LWP::UserAgent" => "5.815",
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.10",
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



