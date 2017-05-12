
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;
install_share dist => "shares\/app_padadoy";


my %WriteMakefileArgs = (
  "ABSTRACT" => "Simply deploy PSGI applications",
  "AUTHOR" => "Jakob Voss",
  "BUILD_REQUIRES" => {
    "File::Temp" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "File::ShareDir::Install" => "0.03"
  },
  "DISTNAME" => "App-Padadoy",
  "EXE_FILES" => [
    "bin/padadoy"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::Padadoy",
  "PREREQ_PM" => {
    "Carton" => 0,
    "Cwd" => 0,
    "File::Basename" => 0,
    "File::Path" => "2.07",
    "File::ShareDir" => 0,
    "File::Slurp" => 0,
    "File::Spec::Functions" => 0,
    "Getopt::Long" => 0,
    "Git::Repository" => 0,
    "HTTP::Request::Common" => 0,
    "IPC::System::Simple" => 0,
    "List::Util" => 0,
    "Plack::Handler::Starman" => 0,
    "Plack::Test" => 0,
    "Pod::Usage" => 0,
    "Sys::Hostname" => 0,
    "Try::Tiny" => 0,
    "YAML::Any" => 0,
    "autodie" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.125",
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

{
package
MY;
use File::ShareDir::Install qw(postamble);
}


