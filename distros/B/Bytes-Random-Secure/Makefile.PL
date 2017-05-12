use 5.006000;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %PREREQ_PM = (
    'Crypt::Random::Seed'   => '0',    # Provides a high quality seed.
    'Math::Random::ISAAC'   => '0',    # Provides our random number generator.
    'MIME::Base64'          => '0',    # Core.
    'MIME::QuotedPrint'     => '3.03', # Core, but minimum version requirement.
    'Carp'                  => '0',    # Core.
    'Scalar::Util'          => '1.21', # Core, but minimum version requirement.
);

WriteMakefile(
    NAME          => 'Bytes::Random::Secure',
    AUTHOR        => q{David Oswald <davido@cpan.org>},
    VERSION_FROM  => 'lib/Bytes/Random/Secure.pm',
    ABSTRACT_FROM => 'lib/Bytes/Random/Secure.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    CONFIGURE_REQUIRES => {
      'ExtUtils::MakeMaker' => '6.56',
    },
    BUILD_REQUIRES => {
      'Test::More'    => '0.98',    # A recent version is needed.
    },
    MIN_PERL_VERSION => '5.006000',
    PREREQ_PM => \%PREREQ_PM,
    META_MERGE => {
      'resources' => {
        'meta-spec' => { version => 2 }, 
        'repository'  => {
          'url'   => 'git://github.com/daoswald/Bytes-Random-Secure.git',
          'web'   => 'http://github.com/daoswald/Bytes-Random-Secure',
          'type'  => 'git',
        },
      },
    },
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean     => { FILES => 'Bytes-Random-Secure-*',       },
);
