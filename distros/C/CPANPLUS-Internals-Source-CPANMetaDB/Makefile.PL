
use strict;
use warnings;

use 5.006000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "CPAN Meta DB source implementation",
  "AUTHOR" => "Chris Williams <chris\@bingosnet.co.uk>, Jos Boumans <kane\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "CPANPLUS-Internals-Source-CPANMetaDB",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "CPANPLUS::Internals::Source::CPANMetaDB",
  "PREREQ_PM" => {
    "CPANPLUS" => "0.9001",
    "File::Fetch" => 0,
    "File::Spec" => 0,
    "Locale::Maketext::Simple" => 0,
    "Module::Load::Conditional" => 0,
    "Params::Check" => 0,
    "Parse::CPAN::Meta" => 0
  },
  "VERSION" => "0.06",
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



