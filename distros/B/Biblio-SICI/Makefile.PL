
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Provides methods for assembling, parsing, manipulating and serialising SICIs",
  "AUTHOR" => "Heiko Jansen <hjansen\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Biblio-SICI",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Biblio::SICI",
  "PREREQ_PM" => {
    "Business::ISSN" => 0,
    "Moo" => 0,
    "Text::Undiacritic" => 0,
    "Text::Unidecode" => 0,
    "Try::Tiny" => 0
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.04",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Business::ISSN" => 0,
  "Moo" => 0,
  "Text::Undiacritic" => 0,
  "Text::Unidecode" => 0,
  "Try::Tiny" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



