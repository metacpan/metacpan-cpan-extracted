
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A command line tool for launching POE::Component::IRC clients",
  "AUTHOR" => "Hinrik \303\226rn Sigur\303\260sson <hinrik.sig\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Test::More" => "0.47",
    "Test::Script" => "1.07"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-Pocoirc",
  "EXE_FILES" => [
    "bin/pocoirc"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::Pocoirc",
  "PREREQ_PM" => {
    "Class::Load" => "0.20",
    "Data::Dump" => 0,
    "IO::WrapOutput" => "0.02",
    "IRC::Utils" => "0.07",
    "JSON::XS" => 0,
    "Module::Pluggable" => 0,
    "POE" => "1.310",
    "POE::Component::Client::DNS" => "0.99",
    "POE::Component::IRC::State" => "6.61",
    "Proc::Daemon" => "0.02",
    "Term::ANSIColor" => 0,
    "Term::Cap" => "1.10",
    "Term::ReadKey" => "2.21",
    "YAML::XS" => 0
  },
  "VERSION" => "0.47",
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



