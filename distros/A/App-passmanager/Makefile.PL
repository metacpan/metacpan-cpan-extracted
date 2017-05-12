
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Command-Line Shared Password Store",
  "AUTHOR" => "Oliver Gorwits <oliver\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-passmanager",
  "EXE_FILES" => [
    "bin/passmanager"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::passmanager",
  "PREREQ_PM" => {
    "Curses" => 0,
    "Curses::UI" => 0,
    "File::Path" => 0,
    "Git::Wrapper" => 0,
    "GnuPG::Interface" => 0,
    "IO::File" => 0,
    "IO::Handle" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "MooseX::App::Cmd" => 0,
    "MooseX::App::Cmd::Command" => 0,
    "Scalar::Util" => 0,
    "XML::Simple" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.113580",
  "test" => {
    "TESTS" => ""
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



