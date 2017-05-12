
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Integrate Github and Beeminder",
  "AUTHOR" => "Jonathan \"Duke\" Leto <jonathan\@leto.net>",
  "BUILD_REQUIRES" => {
    "Dancer::Test" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-Beeminder-Hook",
  "EXE_FILES" => [
    "bin/app.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::Beeminder::Hook",
  "PREREQ_PM" => {
    "Dancer" => 0,
    "Data::Dumper" => 0,
    "JSON::Any" => 0,
    "YAML" => 0,
    "autodie" => 0
  },
  "VERSION" => "0.003",
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



