#!perl

use 5.010000;

use strict;
use warnings;
use ExtUtils::MakeMaker;

# perhaps stolen from mauke/Dir-Self
sub merge_key_into {
  my ( $href, $target, $source ) = @_;
  %{ $href->{$target} } = ( %{ $href->{$target} }, %{ delete $href->{$source} } );
}

my %params = (
  NAME         => 'App::MusicTools',
  AUTHOR       => 'Jeremy Mates <jmates@cpan.org>',
  ABSTRACT     => 'command line utilities for music composition and analysis',
  VERSION_FROM => 'lib/App/MusicTools.pm',

  EXE_FILES => [
    qw/atonal-util canonical harmonic-fit ly-fu scalemogrifier varionator vov/
  ],

  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => 5.14.0,

  CONFIGURE_REQUIRES => {
    'strict'              => 0,
    'ExtUtils::MakeMaker' => '6.48',
  },
  BUILD_REQUIRES => {},
  TEST_REQUIRES  => {
    'Test::Cmd'       => 0,
    'Test::Exception' => 0,
    'Test::Most'      => 0,
    # Mandate the POD tests, contrary to the dagolden no-pod-tests fad. I rank
    # documentation on par with the code, not something one can maybe remember
    # to maybe run the release testing for.
    'Pod::Coverage'       => 0.18,
    'Test::Pod::Coverage' => 1.08,
    'Test::Pod'           => 1.22,
    'lib'                 => 0,
  },
  # List everything due to certain linux vendors chopping up core perl, or
  # otherwise to detect and fail if being installed to a broken perl install.
  PREREQ_PM => {
    Carp                      => 0,
    'File::Spec'              => 0,
    'File::Temp'              => 0,
    'Getopt::Long'            => 0,
    'IPC::Run3'               => 0,
    'JSON'                    => 0,
    'List::Util'              => 0,
    'Music::AtonalUtil'       => 1.14,
    'Music::Canon'            => 2.00,
    'Music::Chord::Positions' => 0,
    'Music::LilyPondUtil'     => 0.10,
    'Music::Scala'            => 0.84,
    'Music::Scales'           => 0,
    'Music::Tempo'            => 0,
    'Music::Tension'          => 0.60,
    'Parse::Range'            => 0,
    'Scalar::Util'            => 0,
    'Text::Roman'             => 0,
    'Text::Wrap'              => 0,
    'Try::Tiny'               => 0,
  },

  META_MERGE => {
    'meta-spec' => { version => 2 },
    'resources' => {
      repository => {
        url  => 'git://github.com/thrig/App-MusicTools.git',
        web  => 'https://github.com/thrig/App-MusicTools',
        type => 'git',
      },
    },
  },

  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'App-MusicTools-*' },
);

( my $mm_version = ExtUtils::MakeMaker->VERSION(
    $params{CONFIGURE_REQUIRES}{'ExtUtils::MakeMaker'}
  )
) =~ tr/_//d;

if ( $mm_version < 6.67_04 ) {
  # also stolen from mauke
  *ExtUtils::MM_Any::_add_requirements_to_meta_v1_4 =
    \&ExtUtils::MM_Any::_add_requirements_to_meta_v2;
}

if ( $mm_version < 6.63_03 ) {
  merge_key_into \%params, 'BUILD_REQUIRES', 'TEST_REQUIRES';
}

if ( $mm_version < 6.55_01 ) {
  merge_key_into \%params, 'CONFIGURE_REQUIRES', 'BUILD_REQUIRES';
}

if ( $mm_version < 6.51_03 ) {
  merge_key_into \%params, 'PREREQ_PM', 'CONFIGURE_REQUIRES';
}

WriteMakefile( ( MM->can('signature_target') ? ( SIGN => 1 ) : () ), %params );
