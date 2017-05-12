
use strict;
use warnings;

use 5.012000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl twist on the most useful PHP function ever - addslashes",
  "AUTHOR" => "James Aitken <jaitken\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => "0.96"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Acme-Addslashes",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Acme::Addslashes",
  "PREREQ_PM" => {
    "Exporter" => "5.65",
    "parent" => "0.224"
  },
  "VERSION" => "0.1.3",
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



