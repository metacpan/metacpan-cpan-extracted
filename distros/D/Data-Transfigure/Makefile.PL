# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.031.
use strict;
use warnings;

use 5.026000;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "performs rule-based data transfigurations of arbitrary structures",
  "AUTHOR" => "Mark Tyrrell <mark\@tyrrminal.dev>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Data-Transfigure",
  "LICENSE" => "mit",
  "MIN_PERL_VERSION" => "5.026000",
  "NAME" => "Data::Transfigure",
  "PREREQ_PM" => {
    "Data::Compare" => "1.29",
    "DateTime::Format::Duration::ISO8601" => "0.008",
    "Module::Util" => "1.09",
    "Object::Pad" => "0.802",
    "Readonly" => "2.05",
    "String::CamelSnakeKebab" => "0.06"
  },
  "TEST_REQUIRES" => {
    "DBIx::Class" => 0,
    "DBIx::Class::InflateColumn::Time" => "0.0.1",
    "DBIx::Class::Relationship::Predicate" => "0.07",
    "DateTime" => 0,
    "DateTime::Duration" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "JSON::Validator" => "5.1.4",
    "Test2::Suite" => "0.000155",
    "Test::More" => 0
  },
  "VERSION" => "1.03",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "DBIx::Class" => 0,
  "DBIx::Class::InflateColumn::Time" => "0.0.1",
  "DBIx::Class::Relationship::Predicate" => "0.07",
  "Data::Compare" => "1.29",
  "DateTime" => 0,
  "DateTime::Duration" => 0,
  "DateTime::Format::Duration::ISO8601" => "0.008",
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "JSON::Validator" => "5.1.4",
  "Module::Util" => "1.09",
  "Object::Pad" => "0.802",
  "Readonly" => "2.05",
  "String::CamelSnakeKebab" => "0.06",
  "Test2::Suite" => "0.000155",
  "Test::More" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
