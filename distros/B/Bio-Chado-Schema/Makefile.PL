
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A standard DBIx::Class layer for the Chado database schema.",
  "AUTHOR" => "Robert Buels <rbuels\@cpan.org>",
  "BUILD_REQUIRES" => {
    "DBD::SQLite" => "1.14",
    "FindBin" => 0,
    "SQL::Translator" => "0.11005",
    "Test::Exception" => "0.27",
    "Test::More" => "0.87",
    "Test::Warn" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Bio-Chado-Schema",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Bio::Chado::Schema",
  "PREREQ_PM" => {
    "Bio::PrimarySeq" => 0,
    "Bio::Range" => 0,
    "Bio::Root::Version" => "1.005002",
    "Carp" => 0,
    "Carp::Clan" => 0,
    "DBIx::Class" => 0,
    "DBIx::Class::Core" => 0,
    "DBIx::Class::ResultSet" => 0,
    "DBIx::Class::Schema" => 0,
    "DBIx::Class::Tree::NestedSet" => "0.07",
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.20000",
  "test" => {
    "TESTS" => "t/*.t t/Cv/*.t t/Phylogeny/*.t t/Sequence/*.t t/Stock/*.t"
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



