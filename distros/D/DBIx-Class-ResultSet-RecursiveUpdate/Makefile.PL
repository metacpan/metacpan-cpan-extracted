
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "like update_or_create - but recursive",
  "AUTHOR" => "Zbigniew Lukasiak <zby\@cpan.org>, John Napiorkowski <jjnapiork\@cpan.org>, Alexander Hartmaier <abraxxa\@cpan.org>, Gerda Shank <gshank\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "DBIx-Class-ResultSet-RecursiveUpdate",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "DBIx::Class::ResultSet::RecursiveUpdate",
  "PREREQ_PM" => {
    "Carp::Clan" => "6.04",
    "DBD::SQLite" => "1.21",
    "DBIx::Class" => "0.08103",
    "DBIx::Class::IntrospectableM2M" => 0,
    "DateTime" => 0,
    "List::MoreUtils" => "0.22",
    "Readonly" => "1.03",
    "SQL::Translator" => "0.11016"
  },
  "TEST_REQUIRES" => {
    "Test::More" => "0.88",
    "Test::Trap" => "v0.2.2",
    "Test::Warn" => "0.20"
  },
  "VERSION" => "0.34",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp::Clan" => "6.04",
  "DBD::SQLite" => "1.21",
  "DBIx::Class" => "0.08103",
  "DBIx::Class::IntrospectableM2M" => 0,
  "DateTime" => 0,
  "List::MoreUtils" => "0.22",
  "Readonly" => "1.03",
  "SQL::Translator" => "0.11016",
  "Test::More" => "0.88",
  "Test::Trap" => "v0.2.2",
  "Test::Warn" => "0.20"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



