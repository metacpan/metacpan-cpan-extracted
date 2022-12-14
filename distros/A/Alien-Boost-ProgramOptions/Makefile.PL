use strict;
use warnings;
use ExtUtils::MakeMaker;
use Alien::Build::MM;

if ( -e '.gitignore' ) {
    system('podselect lib/Alien/Boost/ProgramOptions.pm > README.pod');
}

if ( $^O eq 'MSWin32' ) {
    print STDERR "Win32 is currently not supported";
    exit(0);
}

my %WriteMakefileArgs = (
  "ABSTRACT" => "Find or build libboost",
  "AUTHOR" => "Thibault Duponchelle <thibault.duponchelle\@gmail.com>",
  "VERSION_FROM" => "lib/Alien/Boost/ProgramOptions.pm",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.52",
  },
  "DISTNAME" => "Alien-Boost-ProgramOptions",
  "LICENSE" => "perl",
  "NAME" => "Alien::Boost::ProgramOptions",
  "PREREQ_PM" => {
    "Alien::Base" => "0.038",
    "Test::Alien" => "0",
    "Test::Alien::Diag" => "0",
    "Test::Alien::CPP" => "0",
  },
  META_MERGE => {
        no_index => {
            # Module::Metadata is inferring version from $version::VERSION
            # "in" is a PAUSE misparse.
            package   => [ qw(DynaLoader in version) ],
            directory => [ qw(bundled my) ],
        },
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            homepage    => 'https://metacpan.org/release/Alien-Boost-ProgramOptions',
            bugtracker  => 'https://github.com/thibaultduponchelle/Alien-Boost-ProgramOptions/issues',
            repository  => 'https://github.com/thibaultduponchelle/Alien-Boost-ProgramOptions.git',
            IRC         => 'irc://irc.perl.org/#native'
        },
    },
);

my $abmm = Alien::Build::MM->new;
%WriteMakefileArgs = $abmm->mm_args(%WriteMakefileArgs);

WriteMakefile(%WriteMakefileArgs);

sub MY::postamble {
  $abmm->mm_postamble;
}
