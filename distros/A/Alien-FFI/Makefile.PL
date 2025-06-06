BEGIN {
  use strict; use warnings;
  unless(eval q{ use 5.006; 1}) {
    print "Perl 5.006 or better required\n";
    exit;
  }
}
# This file was automatically generated by Dist::Zilla::Plugin::Author::Plicease::MakeMaker v2.72.
use strict;
use warnings;
use 5.006;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT"       => "Build and make available libffi",
  "AUTHOR"         => "Graham Ollis <plicease\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Alien::Build"        => "2.10",
    "Alien::Build::MM"    => "2.10",
    "ExtUtils::MakeMaker" => "6.52"
  },
  "CONFIGURE_REQUIRES" => {
    "Alien::Build"                           => "2.10",
    "Alien::Build::MM"                       => "2.10",
    "Alien::Build::Plugin::Download::GitHub" => "0.09",
    "Alien::Build::Plugin::Probe::Vcpkg"     => 0,
    "ExtUtils::MakeMaker"                    => "6.52"
  },
  "DISTNAME"         => "Alien-FFI",
  "LICENSE"          => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME"             => "Alien::FFI",
  "PM"               => {
    "lib/Alien/FFI.pm" => "\$(INST_LIB)/Alien/FFI.pm"
  },
  "PREREQ_PM" => {
    "Alien::Base" => "2.10"
  },
  "TEST_REQUIRES" => {
    "Capture::Tiny" => 0,
    "IPC::Cmd"      => 0,
    "Test2::V0"     => "0.000121",
    "Test::Alien"   => 0
  },
  "VERSION" => "0.27",
  "test"    => {
    "TESTS" => "t/*.t"
  }
);

my %FallbackPrereqs = (
  "Alien::Base"         => "2.10",
  "Alien::Build"        => "2.10",
  "Alien::Build::MM"    => "2.10",
  "Capture::Tiny"       => 0,
  "ExtUtils::MakeMaker" => "6.52",
  "IPC::Cmd"            => 0,
  "Test2::V0"           => "0.000121",
  "Test::Alien"         => 0
);

# BEGIN code inserted by Dist::Zilla::Plugin::AlienBuild
use Alien::Build::MM;
my $abmm = Alien::Build::MM->new;
%WriteMakefileArgs = $abmm->mm_args(%WriteMakefileArgs);

# END code inserted by Dist::Zilla::Plugin::AlienBuild

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

# BEGIN code inserted by Dist::Zilla::Plugin::AlienBuild
{ package
    MY;

  sub postamble {
    $abmm->mm_postamble(@_);
  }

  sub install {
    $abmm->can('mm_install')
      ? $abmm->mm_install(@_)
      : shift->SUPER::install(@_);
  }
}

# END code inserted by Dist::Zilla::Plugin::AlienBuild