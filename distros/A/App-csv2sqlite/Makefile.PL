
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Import CSV files into a SQLite database",
  "AUTHOR" => "Randy Stauner <rwstauner\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Exporter" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Find" => 0,
    "File::Spec::Functions" => 0,
    "File::Temp" => "0.19",
    "List::Util" => 0,
    "Test::More" => "0.96",
    "Try::Tiny" => "0.09",
    "utf8" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-csv2sqlite",
  "EXE_FILES" => [
    "bin/csv2sqlite"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::csv2sqlite",
  "PREREQ_PM" => {
    "DBD::SQLite" => 1,
    "DBI" => "1.6",
    "DBIx::TableLoader::CSV" => "1.102",
    "Getopt::Long" => "2.34",
    "Moo" => 1,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.004",
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



