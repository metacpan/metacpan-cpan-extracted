
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Sereal stream serializer/deserializer for AnyEvent",
  "AUTHOR" => "Maxime SoulE<eacute> <btik-cpan\@scoubidou.com>",
  "BUILD_REQUIRES" => {
    "AnyEvent::Impl::Perl" => 0,
    "AnyEvent::Util" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "AnyEvent-Sereal",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "AnyEvent::Sereal",
  "PREREQ_PM" => {
    "AnyEvent" => 0,
    "AnyEvent::Handle" => 0,
    "Sereal::Decoder" => "0.09",
    "Sereal::Encoder" => "0.09",
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.004",
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



