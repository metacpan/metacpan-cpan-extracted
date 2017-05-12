
use strict;
use warnings;

use 5.005;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Parse an environment variable and unshift into \@ARGV",
  "AUTHOR" => "Olivier Mengu\303\251 <dolmen\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0,
    "Test::NoWarnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "ARGV-ENV",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "ARGV::ENV",
  "PREREQ_PM" => {
    "Text::ParseWords" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.00",
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



