#!/usr/bin/perl

# Creation date: 2003-08-13 20:59:11
# Authors: Don
# Change log:
# $Id: Makefile.PL,v 1.3 2003/10/19 07:04:11 don Exp $

use strict;
use Carp;

# main
{
    local($SIG{__DIE__}) = sub { &Carp::cluck(); exit 0 };

    use ExtUtils::MakeMaker;

    WriteMakefile(
                  NAME => 'Apache::Authen::Generic',
                  DISTNAME => 'Apache-Authen-Generic',
                  VERSION_FROM => 'Generic.pm',
                  ABSTRACT => 'Apache Authentication Module',
                  AUTHOR => 'DON OWENS <don@owensnet.com>',
                  PM => { 'Generic.pm' => '$(INST_LIBDIR)/Generic.pm',
                        },
                  dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
                  DIR => [],
                  EXE_FILES => [],
                  PREREQ_PM => { 'Crypt::CBC' => '2.08', # 1.25 is known not to work
                                 'Crypt::Rijndael' => 0,
                                 'MIME::Base64' => 0,
                                 'Digest::SHA1' => 0, mod_perl => 0,
                               },
                  );


}

exit 0;

###############################################################################
# Subroutines

