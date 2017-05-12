
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Query your database using iterators and save memory",
  "AUTHOR" => "Robin Smidsr\303\270d <robin\@smidsrod.no>",
  "BUILD_REQUIRES" => {
    "DBI" => 0,
    "SQL::Statement" => "1.401",
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "DBIx-Iterator",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "DBIx::Iterator",
  "PREREQ_PM" => {
    "Carp" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.0.2",
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



