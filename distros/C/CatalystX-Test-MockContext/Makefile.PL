
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Conveniently create \$c objects for testing",
  "AUTHOR" => "Eden Cardim <edencardim\@gmail.com>",
  "BUILD_REQUIRES" => {
    "Catalyst" => 0,
    "Catalyst::Controller" => 0,
    "English" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "HTTP::Request::Common" => 0,
    "Moose" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "CatalystX-Test-MockContext",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "CatalystX::Test::MockContext",
  "PREREQ_PM" => {
    "Class::Load" => 0,
    "Plack::Test" => 0,
    "Sub::Exporter" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.000001",
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



