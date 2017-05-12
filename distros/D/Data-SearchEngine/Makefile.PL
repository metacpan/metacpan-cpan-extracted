
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A role for search engine abstraction.",
  "AUTHOR" => "Cory G Watson <gphat\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0,
    "Time::HiRes" => 0,
    "strict" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Data-SearchEngine",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Data::SearchEngine",
  "PREREQ_PM" => {
    "Data::Paginator" => "0.03",
    "Digest::MD5" => 0,
    "JSON::Any" => 0,
    "JSON::XS" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "MooseX::Storage" => 0,
    "MooseX::Storage::Deferred" => 0
  },
  "VERSION" => "0.33",
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



