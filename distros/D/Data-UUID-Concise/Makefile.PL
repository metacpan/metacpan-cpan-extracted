
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Encode UUIDs to be more concise or communicable",
  "AUTHOR" => "Nathaniel Reindl <nrr\@corvidae.org>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Data-UUID-Concise",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Data::UUID::Concise",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Data::UUID" => 0,
    "List::MoreUtils" => 0,
    "Math::BigInt" => 0,
    "Moo" => 0,
    "MooX::Types::MooseLike::Base" => 0,
    "charnames" => 0,
    "open" => 0,
    "strictures" => 1,
    "utf8" => 0
  },
  "VERSION" => "0.121240",
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



