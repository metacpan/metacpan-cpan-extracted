# This -*- perl -*- script makes the Makefile

use 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Convert::BER',
  VERSION_FROM => 'BER.pm',
  ( eval { ExtUtils::MakeMaker->VERSION(6.21) }
    ? (
      LICENSE  => 'perl',
      AUTHOR   => 'Graham Barr <gbarr@pobox.com>',
      ABSTRACT => 'Encode/decoing of ASN.1 using BER rules'
      )
    : ()
  ),
);
