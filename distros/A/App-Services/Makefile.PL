
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Makes reusable services easy\r",
  "AUTHOR" => "Sean Blanton <sean\@blanton.com>",
  "BUILD_REQUIRES" => {
    "POSIX" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-Services",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "App::Services",
  "PREREQ_PM" => {
    "Bread::Board" => 0,
    "Bread::Board::Container" => 0,
    "Carp" => 0,
    "DBI" => 0,
    "KiokuDB" => 0,
    "KiokuDB::Backend::DBI" => 0,
    "Log::Dispatch::Screen" => 0,
    "Log::Log4perl" => 0,
    "Moo" => 0,
    "Moo::Role" => 0,
    "MooX::Types::MooseLike::Base" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "Net::SMTP" => 0,
    "common::sense" => 0
  },
  "VERSION" => "0.002",
  "test" => {
    "TESTS" => "t/App/Services/DB/*.t t/App/Services/Forker/*.t t/App/Services/Logger/*.t t/App/Services/ObjStore/*.t"
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



