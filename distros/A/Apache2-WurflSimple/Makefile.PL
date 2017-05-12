
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "module that the Wurfl Perl client to retrieve capabilities data from the Wurfl server",
  "AUTHOR" => "Uri Bruck <uri\@bruck.co.il>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Apache2-WurflSimple",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Apache2::WurflSimple",
  "PREREQ_PM" => {
    "APR::Table" => 0,
    "Apache2::CmdParms" => 0,
    "Apache2::Const" => 0,
    "Apache2::Directive" => 0,
    "Apache2::Module" => 0,
    "Apache2::RequestRec" => 0,
    "Apache2::ServerUtil" => 0,
    "Apache::Test" => 0,
    "Apache::TestUtil" => 0,
    "Cache::File" => 0,
    "Net::WURFL::ScientiaMobile" => 0,
    "Net::WURFL::ScientiaMobile::Cache::Cookie" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.002",
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



