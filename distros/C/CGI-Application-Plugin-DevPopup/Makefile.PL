
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Runtime cgiapp info in a popup window",
  "AUTHOR" => "Rhesa Rozendaal <rhesa\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "CGI-Application-Plugin-DevPopup",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "CGI::Application::Plugin::DevPopup",
  "PREREQ_PM" => {
    "CGI::Application" => "4.01",
    "HTML::Template" => 0,
    "IO::Scalar" => 0,
    "Test::More" => 0,
    "Time::HiRes" => 0
  },
  "VERSION" => "1.08",
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



