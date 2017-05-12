#!/usr/bin/perl -sw
##
## Makefile.PL for Conver::ASCII::Armour
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: Makefile.PL,v 1.2 2001/03/19 23:02:47 vipul Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	       => 'Convert::ASCII::Armour',
    'AUTHOR'       => 'Vipul Ved Prakash <mail@vipul.net>',
    'VERSION_FROM' => 'lib/Convert/ASCII/Armour.pm',
    'PREREQ_PM'    => { 'Digest::MD5'        => 0,
                        'MIME::Base64'       => 0,
                        'Compress::Zlib'     => 0,
                      },
);


