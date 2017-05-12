
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Tiny asynchronous (non-blocking) interface to EC2 using AnyEvent",
  "AUTHOR" => "Sawyer X <xsawyerx\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Data::Dumper" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "AnyEvent-EC2-Tiny",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "AnyEvent::EC2::Tiny",
  "PREREQ_PM" => {
    "AnyEvent::HTTP" => 0,
    "Carp" => 0,
    "HTTP::Tiny" => 0,
    "Moo" => 0,
    "Net::EC2::Tiny" => 0
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



