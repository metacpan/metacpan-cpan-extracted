#!/usr/bin/env perl
use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Crypt::MagicSignatures::Key',
  AUTHOR       => 'Nils Diewald',
  ABSTRACT     => 'MagicKeys for the Salmon Protocol',
  VERSION_FROM => 'lib/Crypt/MagicSignatures/Key.pm',
  BUILD_REQUIRES => {
    'Test::More' => 0,
    'Test::Output' => 0,
    'Sub::Util' => 0
  },
  PREREQ_PM => {
    'Math::Prime::Util' => '0.65',
    'Carp'         => 0,
    'Digest::SHA'  => 0,
    'MIME::Base64' => '3.15',
    'Math::BigInt' => '1.89',
    'Exporter'     => 0,
  },
  LICENSE => 'artistic_2',
  META_MERGE   => {
    'meta-spec' => { version => 2 },
    requires  => { perl => '5.010001' },
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => {
        type => 'git',
        url => 'https://github.com/Akron/Crypt-MagicSignatures-Key.git',
        web => 'https://github.com/Akron/Crypt-MagicSignatures-Key',
      },
      bugtracker => {
        web => 'https://github.com/Akron/Crypt-MagicSignatures-Key/issues'
      }
    },
    recommends => {
      'Math::Prime::Util::GMP'  => 0.34,
      'Math::BigInt::GMP'       => 1.44, # 1.51
      'Math::Random::ISAAC::XS' => 1.004,
    }
  },
  MIN_PERL_VERSION => '5.010001',
  test => {TESTS => 't/*.t'}
);

