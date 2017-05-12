# Makefile.PL for Device::Citizen3540 module  -*- perl -*-

use ExtUtils::MakeMaker;

WriteMakefile (
    NAME         => 'Device::Citizen3540',
    DISTNAME     => 'Citizen3540',
    ($] >= 5.006 ?
     (INSTALLDIRS => 'perl') : ()),
    ($] >= 5.005 ?
     (ABSTRACT   => 'POS Dot Matrix printer control',
      AUTHOR     => 'Scott Peshak (speshak@gmail.com)') : ()),
    VERSION_FROM => 'Citizen3540.pm',
    dist         => { COMPRESS => 'gzip', SUFFIX => 'gz' }
);
