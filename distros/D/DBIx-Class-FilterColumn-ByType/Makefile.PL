
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Apply FilterColumn by type instead of name",
  "AUTHOR" => "Matthew Phillips <mattp\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Carp" => 0,
    "DBIx::Class::Core" => 0,
    "DBIx::Class::Schema" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Scalar::Util" => 0,
    "Test::Deep" => 0,
    "Test::More" => "0.94"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "DBIx-Class-FilterColumn-ByType",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "DBIx::Class::FilterColumn::ByType",
  "PREREQ_PM" => {
    "DBIx::Class::FilterColumn" => 0,
    "SQL::Translator" => "0.11006",
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.122121",
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



