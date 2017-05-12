
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Migrate an existing database to another backend",
  "AUTHOR" => "Maik Hentsche <caldrin\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Class::C3" => 0,
    "DBIx::Class::Core" => 0,
    "DBIx::Class::FilterColumn" => 0,
    "DBIx::Class::InflateColumn::DateTime" => 0,
    "DBIx::Class::Schema" => 0,
    "DBIx::Class::TimeStamp" => 0,
    "English" => 0,
    "MRO::Compat" => 0,
    "Test::Fixture::DBIC::Schema" => 0,
    "Test::More" => 0,
    "parent" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "DBICx-Backend-Move",
  "EXE_FILES" => [
    "bin/dbicx-backend-move"
  ],
  "LICENSE" => "perl",
  "NAME" => "DBICx::Backend::Move",
  "PREREQ_PM" => {
    "App::Cmd::Simple" => 0,
    "DBI" => 0,
    "DBICx::Deploy" => 0,
    "Module::Load" => 0,
    "Moo" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.000010",
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



