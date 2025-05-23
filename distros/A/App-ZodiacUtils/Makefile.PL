# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.012.
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "CLI utilities related to zodiac",
  "AUTHOR" => "perlancar <perlancar\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "App-ZodiacUtils",
  "EXE_FILES" => [
    "script/_chinese-zodiac-of",
    "script/_zodiac-of",
    "script/chinese-zodiac-of",
    "script/list-chinese-zodiac-table",
    "script/zodiac-of"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010001",
  "NAME" => "App::ZodiacUtils",
  "PREREQ_PM" => {
    "Data::Sah::Coerce::perl::To_date::From_float::epoch" => 0,
    "Data::Sah::Coerce::perl::To_date::From_obj::datetime" => 0,
    "Data::Sah::Coerce::perl::To_date::From_obj::time_moment" => 0,
    "Data::Sah::Coerce::perl::To_date::From_str::iso8601" => 0,
    "Data::Sah::Compiler::perl::TH::array" => 0,
    "Data::Sah::Compiler::perl::TH::bool" => 0,
    "Data::Sah::Compiler::perl::TH::date" => 0,
    "Data::Sah::Compiler::perl::TH::int" => 0,
    "Data::Sah::Compiler::perl::TH::str" => 0,
    "DateTime" => 0,
    "DateTime::Format::Alami::EN" => "0.13",
    "DateTime::Format::Natural" => 0,
    "List::Util" => "1.45",
    "Perinci::CmdLine::Any" => 0,
    "Perinci::CmdLine::Lite" => "1.827",
    "Perinci::Sub::Gen::AccessTable" => "0.583",
    "Perinci::Sub::Property::result::table" => 0,
    "Scalar::Util" => 0,
    "Zodiac::Chinese::Table" => 0,
    "Zodiac::Tiny" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.115",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Data::Sah::Coerce::perl::To_date::From_float::epoch" => 0,
  "Data::Sah::Coerce::perl::To_date::From_obj::datetime" => 0,
  "Data::Sah::Coerce::perl::To_date::From_obj::time_moment" => 0,
  "Data::Sah::Coerce::perl::To_date::From_str::iso8601" => 0,
  "Data::Sah::Compiler::perl::TH::array" => 0,
  "Data::Sah::Compiler::perl::TH::bool" => 0,
  "Data::Sah::Compiler::perl::TH::date" => 0,
  "Data::Sah::Compiler::perl::TH::int" => 0,
  "Data::Sah::Compiler::perl::TH::str" => 0,
  "DateTime" => 0,
  "DateTime::Format::Alami::EN" => "0.13",
  "DateTime::Format::Natural" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "List::Util" => "1.45",
  "Perinci::CmdLine::Any" => 0,
  "Perinci::CmdLine::Lite" => "1.827",
  "Perinci::Sub::Gen::AccessTable" => "0.583",
  "Perinci::Sub::Property::result::table" => 0,
  "Scalar::Util" => 0,
  "Test::More" => 0,
  "Zodiac::Chinese::Table" => 0,
  "Zodiac::Tiny" => 0,
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
