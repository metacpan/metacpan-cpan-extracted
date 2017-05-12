
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Add Config::Std support to CGI::Application",
  "AUTHOR" => "Stephen Cardie <stephenca\@cpan.org>",
  "BUILD_REQUIRES" => {
    "English" => 0,
    "File::Spec" => 0,
    "Test::More" => 0,
    "Test::Most" => 0,
    "Test::Perl::Critic" => 0,
    "Test::Pod" => 0,
    "Test::Pod::Coverage" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "CGI-Application-Plugin-Config-Std",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "CGI::Application::Plugin::Config::Std",
  "PREREQ_PM" => {
    "CGI::Application" => 0,
    "Config::Std" => 0,
    "Hash::Merge" => "0.12",
    "Sub::Exporter" => "0.982",
    "common::sense" => "3.4"
  },
  "VERSION" => "1.003",
  "test" => {
    "TESTS" => "t/*.t t/lib/cgi/application/plugin/config/*.t"
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



