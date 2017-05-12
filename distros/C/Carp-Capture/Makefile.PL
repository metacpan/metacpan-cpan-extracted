# -*- cperl -*-
use 5.010;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile
    (
     NAME                   => 'Carp::Capture',
     AUTHOR                 => q{Paul Liebert <paull@peak.org>},
     VERSION_FROM           => 'lib/Carp/Capture.pm',
     ABSTRACT_FROM          => 'lib/Carp/Capture.pm',
     LICENSE                => 'Perl_5',
     PL_FILES               =>
     {
     },
     MIN_PERL_VERSION       => 5.010,
     CONFIGURE_REQUIRES     =>
     {
      'ExtUtils::MakeMaker' => '7.00',
     },
     BUILD_REQUIRES         =>
     {
      'Test::More'          => '1.001',
      'Test::Exception'     => '0.32',
     },
     PREREQ_PM              =>
     {
      'warnings'            => '1.18',
      'English'             => '1.06',
      'Moose'               => '2.1005',
      'Readonly'            => '1.04',
      'Carp::Proxy'         => '0.12',
     },
     dist                   =>
     {
      COMPRESS              => 'gzip -9f',
      SUFFIX                => 'gz',
     },
     clean                  =>
     {
      FILES                 => 'Carp-Capture-*'
     },
    );
