use strict;
use warnings;
use ExtUtils::MakeMaker;
use Alien::Build::MM;

if ( -e '.gitignore' ) {
    system('podselect lib/Alien/Gearman.pm > README.pod');
}

if ( $^O eq 'MSWin32' ) {
    print STDERR "Win32 is currently not supported";
    exit(0);
}

my %WriteMakefileArgs = (
  "ABSTRACT" => "Find or build libgearman",
  "AUTHOR" => "Thibault Duponchelle <thibault.duponchelle\@gmail.com>",
  "VERSION_FROM" => "lib/Alien/Gearman.pm",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.52",
  },
  "PREREQ_PM" => {
    "Alien::Base" => "0.038",
    "Alien::libuuid" => "0",
    "Alien::Libevent" => "0",
  },
  "DISTNAME" => "Alien-Gearman",
  "LICENSE" => "perl",
  "NAME" => "Alien::Gearman",
  META_MERGE => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            homepage    => 'https://metacpan.org/release/Alien-Gearman',
            bugtracker  => 'https://github.com/thibaultduponchelle/Alien-Gearman/issues',
            repository  => 'https://github.com/thibaultduponchelle/Alien-Gearman.git',
            IRC         => 'irc://irc.perl.org/#native'
        },
    },
);

my %FallbackPrereqs = (
  "Alien::Base" => "0.038",
  "Alien::libuuid" => "0",
  "Alien::Libevent" => "0",
);

my $abmm = Alien::Build::MM->new;
%WriteMakefileArgs = $abmm->mm_args(%WriteMakefileArgs);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

sub MY::postamble {
  $abmm->mm_postamble;
}
