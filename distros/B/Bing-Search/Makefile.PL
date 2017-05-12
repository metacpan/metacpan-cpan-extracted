
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Implements the Bing AJAX Search API",
  "AUTHOR" => "Dave Houston <dhouston\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Bing-Search",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Bing::Search",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Data::Dumper" => 0,
    "DateTime::Duration" => 0,
    "DateTime::Format::DateParse" => 0,
    "JSON" => "2.21",
    "LWP::UserAgent" => "5.835",
    "Moose" => "1.00",
    "Moose::Role" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "URI" => "1.54",
    "URI::QueryParam" => 0,
    "vars" => 0
  },
  "VERSION" => "1.121210",
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



