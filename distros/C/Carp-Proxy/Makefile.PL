# -*- cperl -*-
use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile
    (
     NAME          => 'Carp::Proxy',
     AUTHOR        => q{Paul Liebert <paull@peak.org>},
     VERSION_FROM  => 'lib/Carp/Proxy.pm',
     ABSTRACT_FROM => 'lib/Carp/Proxy.pm',
     LICENSE       => 'perl',
     MIN_PERL_VERSION => '5.10.0',
     PL_FILES      => {},

     BUILD_REQUIRES =>
     {
      'English'               => 0,
      'File::Basename'        => 0,
      'File::Spec::Functions' => 0,
      'Moose'                 => 0,
      'Pod::Coverage'         => '0.18',
      'Test::Exception'       => 0,
      'Test::More'            => 0,
      'Test::Pod'             => '1.22',
      'Test::Pod::Coverage'   => '1.08',
      'YAML::XS'              => 0,
     },
     PREREQ_PM     =>
     {
      'Config'     => 0,
      'Cwd'        => 0,
      'English'    => 0,
      'Moose'      => 0,
      'overload'   => 0,
      'Pod::Usage' => 0,
      'Readonly'   => 0,
      'Sub::Name'  => 0,
      'YAML::XS'   => 0,
     },

     dist          =>
     {
      COMPRESS     => 'gzip -9f',
      SUFFIX       => 'gz',
     },

     clean         =>
     {
      FILES        => 'Carp-Proxy-*',
     },
);
