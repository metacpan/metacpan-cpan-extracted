
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "GitHub Command Tools",
  "AUTHOR" => "Fayland Lam <fayland\@gmail.com>, William Orr <will\@worrbase.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-GitHub",
  "EXE_FILES" => [
    "scripts/github.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::GitHub",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Getopt::Long" => 0,
    "IPC::Cmd" => 0,
    "JSON::XS" => "2.232",
    "Moose" => 0,
    "Net::GitHub" => "0.43",
    "Pod::Usage" => 0,
    "Term::ReadKey" => 0,
    "Term::ReadLine" => 0
  },
  "VERSION" => "1.0.1",
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



