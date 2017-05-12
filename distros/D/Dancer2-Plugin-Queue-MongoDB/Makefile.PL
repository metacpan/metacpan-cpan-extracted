
use strict;
use warnings;

use 5.008001;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Dancer2::Plugin::Queue backend using MongoDB",
  "AUTHOR" => "David Golden <dagolden\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Dancer2::Plugin::Queue::Role::Test" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Find" => 0,
    "File::Spec::Functions" => 0,
    "File::Temp" => 0,
    "HTTP::Tiny" => 0,
    "List::Util" => 0,
    "MongoDB" => "0.45",
    "MooX::Types::MooseLike::Base" => 0,
    "Test::More" => 0,
    "Test::Roo" => 0,
    "Test::TCP" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Dancer2-Plugin-Queue-MongoDB",
  "EXE_FILES" => [],
  "LICENSE" => "apache",
  "NAME" => "Dancer2::Plugin::Queue::MongoDB",
  "PREREQ_PM" => {
    "Dancer2::Plugin::Queue" => "0.003",
    "Dancer2::Plugin::Queue::Role::Queue" => 0,
    "MongoDB" => 0,
    "MongoDB::MongoClient" => 0,
    "MongoDBx::Queue" => 0,
    "Moose" => 0,
    "strict" => 0,
    "warnings" => 0
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



