
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Run a bogus CPAN web server for testing",
  "AUTHOR" => "Peter Shangov <pshangov\@yahoo.com>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "LWP::Simple" => 0,
    "Module::Faker::Dist" => 0,
    "Module::Faker::Package" => 0,
    "Path::Class" => 0,
    "Test::More" => 0,
    "Test::Most" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "CPAN-Faker-HTTPD",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "CPAN::Faker::HTTPD",
  "PREREQ_PM" => {
    "CPAN::Faker" => 0,
    "File::Temp" => 0,
    "HTTP::Message::PSGI" => 0,
    "Moose" => 0,
    "Plack::App::File" => 0,
    "Test::Fake::HTTPD" => 0,
    "namespace::clean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.002",
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



