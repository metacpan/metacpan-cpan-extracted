# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.024.
use strict;
use warnings;



use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Wordle words (English)",
  "AUTHOR" => "perlancar <perlancar\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "ArrayData-Lingua-Word-EN-Wordle",
  "LICENSE" => "perl",
  "NAME" => "ArrayData::Lingua::Word::EN::Wordle",
  "PREREQ_PM" => {
    "ArrayDataRole::BinarySearch::LinesInHandle" => 0,
    "ArrayDataRole::Source::LinesInDATA" => "0.006",
    "Role::Tiny::With" => 0,
    "Role::TinyCommons::Collection::FindItem::Iterator" => "0.007",
    "Role::TinyCommons::Collection::PickItems::RandomSeekLines" => 0,
    "strict" => 0
  },
  "TEST_REQUIRES" => {
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0
  },
  "VERSION" => "20220306.0.1",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "ArrayDataRole::BinarySearch::LinesInHandle" => 0,
  "ArrayDataRole::Source::LinesInDATA" => "0.006",
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Role::Tiny::With" => 0,
  "Role::TinyCommons::Collection::FindItem::Iterator" => "0.007",
  "Role::TinyCommons::Collection::PickItems::RandomSeekLines" => 0,
  "Test::More" => 0,
  "strict" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
