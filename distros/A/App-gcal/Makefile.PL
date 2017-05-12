
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Command Line Interface interface to Google Calendar.",
  "AUTHOR" => "Andrew Jones <andrew\@arjones.co.uk>",
  "BUILD_REQUIRES" => {
    "English" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "Test::More" => "0.88"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-gcal",
  "EXE_FILES" => [
    "bin/gcal"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::gcal",
  "PREREQ_PM" => {
    "Class::ReturnValue" => 0,
    "Data::ICal" => 0,
    "DateTime::Format::ICal" => 0,
    "DateTime::TimeZone" => 0,
    "File::Basename" => 0,
    "Getopt::Long" => 0,
    "ICal::Format::Natural" => 0,
    "Net::Google::Calendar" => 0,
    "Net::Google::Calendar::Entry" => 0,
    "Net::Netrc" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.121460",
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



