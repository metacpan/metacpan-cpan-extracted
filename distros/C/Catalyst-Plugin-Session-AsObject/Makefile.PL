
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Make your session data an object",
  "AUTHOR" => "Dave Rolsky, E<gt>autarch\@urth.orgE<lt>",
  "BUILD_REQUIRES" => {
    "Test::Fatal" => 0,
    "Test::More" => "0.88",
    "Test::Requires" => 0,
    "Test::Spelling" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Catalyst-Plugin-Session-AsObject",
  "EXE_FILES" => [],
  "LICENSE" => "artistic_2",
  "NAME" => "Catalyst::Plugin::Session::AsObject",
  "PREREQ_PM" => {
    "Catalyst::Plugin::Session" => "0.27",
    "MRO::Compat" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.05",
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



