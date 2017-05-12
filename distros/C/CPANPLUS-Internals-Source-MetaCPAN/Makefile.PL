
use strict;
use warnings;

use 5.006000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "MetaCPAN source implementation",
  "AUTHOR" => "Chris Williams <chris\@bingosnet.co.uk>",
  "BUILD_REQUIRES" => {
    "Test::More" => "0.47"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "CPANPLUS-Internals-Source-MetaCPAN",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "CPANPLUS::Internals::Source::MetaCPAN",
  "PREREQ_PM" => {
    "CPANPLUS" => "0.9001",
    "File::Fetch" => 0,
    "File::Spec" => 0,
    "JSON::PP" => 0,
    "Locale::Maketext::Simple" => 0,
    "Module::Load::Conditional" => 0,
    "Params::Check" => 0,
    "Parse::CPAN::Meta" => 0
  },
  "VERSION" => "0.08",
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



