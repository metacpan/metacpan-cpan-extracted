
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Helps you paginate, search, sort, and more easily using DBIx::Class",
  "AUTHOR" => "Arthur Axel \"fREW\" Schmidt <frioux+cpan\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Catalyst-TraitFor-Controller-DBIC-DoesPaging",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Catalyst::TraitFor::Controller::DBIC::DoesPaging",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Catalyst::Model::DBIC::Schema" => "0.29",
    "Catalyst::Runtime" => "5.80000",
    "Catalyst::Test" => 0,
    "Catalyst::View::JSON" => 0,
    "DBIx::Class" => "0.08108",
    "FindBin" => 0,
    "JSON" => 0,
    "SQL::Translator" => "0.11002",
    "Test::Deep" => 0,
    "Test::More" => "0.88",
    "Web::Util::DBIC::Paging" => 0,
    "parent" => 0
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "1.001003",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

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



