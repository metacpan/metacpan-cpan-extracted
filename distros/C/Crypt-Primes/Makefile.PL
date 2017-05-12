#!/usr/bin/perl -sw
##
## Makefile.PL for Crypt::Primes.
##
## Copyright (c) 1998, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id$

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	     => 'Crypt::Primes',
    VERSION_FROM => 'lib/Crypt/Primes.pm', 
    EXE_FILES    => [ "bin/largeprimes",
                    ],
    PREREQ_PM    => { 'Math::Pari' => '2.001804', 
                      'Crypt::Random' => '0.33', 
                    }, 
    
);
