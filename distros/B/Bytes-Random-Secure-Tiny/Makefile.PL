use 5.008000;
use strict;
use warnings;
use ExtUtils::MakeMaker;

use constant WINAPI_SIGNATURE => 281474976710656;

my %PREREQ_PM = $^O eq 'MSWin32'
    ? ('Win32' => 0, 'Win32::API' => (~0 > WINAPI_SIGNATURE ? 0.62 : 0),
       'Win32::API::Type' => 0) 
    : ();

WriteMakefile(
    NAME               => 'Bytes::Random::Secure::Tiny',
    AUTHOR             => q{David Oswald <davido@cpan.org>},
    VERSION_FROM       => 'lib/Bytes/Random/Secure/Tiny.pm',
    ABSTRACT_FROM      => 'lib/Bytes/Random/Secure/Tiny.pod',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE' => 'perl') : ()),
    PL_FILES           => {},
    CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => '6.56'},
    BUILD_REQUIRES     => {'Test::More'          => '0.98'},
    MIN_PERL_VERSION   => '5.008000',
    PREREQ_PM          => \%PREREQ_PM,
    META_MERGE => {
      'meta-spec' => {version => 2},
      'resources' => {
        'repository' => {
          'url'  => 'git://github.com/daoswald/Bytes-Random-Secure-Tiny.git',
          'web'  => 'https://github.com/daoswald/Bytes-Random-Secure-Tiny',
          'type' => 'git',
        },
      },
    },
    dist               => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'  },
    clean              => {FILES    => 'Bytes-Random-Secure-Tiny-*'},
);
