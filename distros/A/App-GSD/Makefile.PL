
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "boost productivity by blocking distracting websites",
  "AUTHOR" => "Richard Harris <RJH\@cpan.org>",
  "BUILD_REQUIRES" => {
    "File::Temp" => 0,
    "Socket" => 0,
    "Test::More" => "0.88"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "File::ShareDir::Install" => "0.03"
  },
  "DISTNAME" => "App-GSD",
  "EXE_FILES" => [
    "bin/get-shit-done"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::GSD",
  "PREREQ_PM" => {
    "Carp" => 0,
    "English" => 0,
    "File::ShareDir" => 0,
    "File::Slurp" => 0,
    "Getopt::Long" => 0,
    "IPC::System::Simple" => 0,
    "Pod::Usage" => 0,
    "YAML" => 0,
    "autodie" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.4",
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

package
MY;
use File::ShareDir::Install qw(postamble);


