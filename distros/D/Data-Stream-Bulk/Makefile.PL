
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "N at a time iteration API",
  "AUTHOR" => "Yuval Kogman <nothingmuch\@woobling.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => "0.88",
    "Test::Requires" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Data-Stream-Bulk",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Data::Stream::Bulk",
  "PREREQ_PM" => {
    "Moose" => "0.90",
    "Path::Class" => 0,
    "Sub::Exporter" => 0,
    "namespace::clean" => 0
  },
  "VERSION" => "0.11",
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



