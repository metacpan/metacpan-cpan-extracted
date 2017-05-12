
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Scripts and Modules to manage PTC(R) ProE/Engineer(R) / Creo(TM) configurations. Use perldoc CAD::Firemen to get an introduction to the usage of this distribution.",
  "AUTHOR" => "Joachim Langenbach <langenbach\@imw.tu-clausthal.de>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "CAD-Firemen",
  "EXE_FILES" => [
    "bin/fm_admin",
    "bin/fm_check_config",
    "bin/fm_check_struct",
    "bin/fm_create_help",
    "bin/fm_diff_cdb",
    "bin/fm_diff_config",
    "bin/fm_option_info"
  ],
  "LICENSE" => "gpl",
  "NAME" => "CAD::Firemen",
  "PREREQ_PM" => {
    "Archive::Zip" => 0,
    "DBI" => 0,
    "Digest::MD5" => 0,
    "Exporter" => 0,
    "File::Basename" => 0,
    "File::Copy" => 0,
    "File::Copy::Recursive" => 0,
    "File::Find" => 0,
    "File::Find::Rule" => 0,
    "File::Path" => 0,
    "File::Spec" => 0,
    "Getopt::Long" => 0,
    "HTML::TreeBuilder" => 0,
    "IO::HTML" => 0,
    "JSON::Parse" => 0,
    "List::Util" => 0,
    "POSIX" => 0,
    "Pod::Usage" => 0,
    "Term::ANSIColor" => 0,
    "Term::ProgressBar" => 0,
    "Term::ReadKey" => 0,
    "Tie::File" => 0,
    "Win32" => 0,
    "Win32::Console::ANSI" => 0,
    "Win32::Shortcut" => 0,
    "XML::LibXML" => 0,
    "YAML::XS" => 0,
    "constant" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Capture::Tiny" => 0,
    "FindBin" => 0,
    "Test::More" => "0.88",
    "Test::Script" => "1.05",
    "blib" => 0,
    "lib" => 0
  },
  "VERSION" => "0.7.2",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

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



