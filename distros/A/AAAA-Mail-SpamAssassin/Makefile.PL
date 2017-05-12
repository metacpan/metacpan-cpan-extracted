
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "making Mail::SpamAssassin installable",
  "AUTHOR" => "Steffen Schwigon <ss5\@renormalist.net>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "AAAA-Mail-SpamAssassin",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "AAAA::Mail::SpamAssassin",
  "PREREQ_PM" => {
    "DB_File" => 0,
    "HTML::Parser" => 0,
    "Net::DNS" => 0,
    "Net::IP" => 0,
    "NetAddr::IP" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.002",
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



