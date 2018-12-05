use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 7.12;

my $preop =
    'pod2markdown lib/Algorithm/LUHN_XS.pm > README.md;' .
    'pod2text  lib/Algorithm/LUHN_XS.pm > README';
my %WriteMakefileArgs = (
  "ABSTRACT" => "Very Fast XS Version of the original Algorithm::LUHN",
  "AUTHOR" => "Kerry Schwab <kschwab\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => '7.12',
    "XSLoader" => '0.16'
  },
  "DISTNAME" => "Algorithm-LUHN_XS",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.008001",
  "NAME" => "Algorithm::LUHN_XS",
  "PREREQ_PM" => {
    "Exporter" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test" => 0,
  },
  dist => {
      PREOP => $preop
  },
  VERSION_FROM => "lib/Algorithm/LUHN_XS.pm",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Exporter" => 0,
  "ExtUtils::MakeMaker" => 0,
  "Test" => 0,
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
