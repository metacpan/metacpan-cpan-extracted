#!/usr/bin/env perl
use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Crypt::MagicSignatures::Envelope',
  AUTHOR       => 'Nils Diewald',
  ABSTRACT     => 'MagicEnvelopes for the Salmon Protocol',
  VERSION_FROM => 'lib/Crypt/MagicSignatures/Envelope.pm',
  BUILD_REQUIRES => {
    'Test::More' => 0
  },
  PREREQ_PM => {
    'Crypt::MagicSignatures::Key' => '0.22',
    'Mojolicious' => '4.82',
    'Carp' => 0,
  },
  LICENSE => 'artistic_2',
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
    'meta-spec' => { version => 2 },
    requires  => { perl => '5.010001' },
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => {
        type => 'git',
        web => 'https://github.com/Akron/Crypt-MagicSignatures-Envelope',
        url => 'https://github.com/Akron/Crypt-MagicSignatures-Envelope.git'
      },
      bugtracker  => {
        web => 'https://github.com/Akron/Crypt-MagicSignatures-Envelope/issues'
      }
    },
    recommends => {
      'Math::Prime::Util::GMP'  => 0.18,
      'Math::BigInt::GMP'       => 0,
      'Math::Random::ISAAC::XS' => 1.004,
    }
  }) : (),
  ),
  MIN_PERL_VERSION => '5.010001',
  test => {TESTS => 't/*.t'}
);

