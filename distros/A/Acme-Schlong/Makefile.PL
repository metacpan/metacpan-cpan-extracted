
use strict;
use warnings;

use 5.014000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "exe-cute-able for Acme::Schlong",
  "AUTHOR" => "Daniel B. <dbr\@cpan.org>",
  "BUILD_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec::Functions" => 0,
    "List::Util" => 0,
    "Module::Build" => "0.3601",
    "Scalar::Util" => 0,
    "Test::CheckDeps" => "0.002",
    "Test::More" => "0.94",
    "Test::UseAllModules" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "Acme-Schlong",
  "EXE_FILES" => [
    "bin/schlong",
    "bin/schlong"
  ],
  "LICENSE" => "unrestricted",
  "NAME" => "Acme::Schlong",
  "PREREQ_PM" => {
    "Acme::Emoticarp" => 0,
    "App::OS::Detect::MachineCores" => 0,
    "Carp" => 0,
    "Config::Any" => 0,
    "Data::Printer" => 0,
    "File::Util" => 0,
    "FindBin" => 0,
    "MetaCPAN::API" => 0,
    "MooseX::AlwaysCoerce" => 0,
    "MooseX::Attribute::ENV" => 0,
    "MooseX::Declare" => 0,
    "MooseX::Getopt::Strict" => 0,
    "MooseX::StrictConstructor" => 0,
    "MooseX::Types::Moose" => 0,
    "MooseX::Types::Path::Class" => 0,
    "MooseX::Types::Perl" => 0,
    "Path::Class" => 0,
    "feature" => 0,
    "strict" => 0,
    "true" => 0,
    "version" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.001",
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



