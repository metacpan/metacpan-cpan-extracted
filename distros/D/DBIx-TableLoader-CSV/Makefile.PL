
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Easily load a CSV into a database table",
  "AUTHOR" => "Randy Stauner <rwstauner\@cpan.org>",
  "BUILD_REQUIRES" => {
    "DBD::Mock" => 0,
    "DBI" => 0,
    "Exporter" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Find" => 0,
    "File::Spec::Functions" => 0,
    "File::Temp" => 0,
    "List::Util" => 0,
    "Symbol" => 0,
    "Test::Fatal" => 0,
    "Test::MockObject" => "1.09",
    "Test::More" => "0.96",
    "Try::Tiny" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "DBIx-TableLoader-CSV",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "DBIx::TableLoader::CSV",
  "PREREQ_PM" => {
    "Carp" => 0,
    "DBIx::TableLoader" => "1.100",
    "File::Basename" => 0,
    "Module::Load" => 0,
    "PerlIO::encoding" => 0,
    "Text::CSV" => "1.21",
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.102",
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



