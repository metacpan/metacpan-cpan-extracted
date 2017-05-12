#!/usr/bin/perl -sw
##
## Makefile.PL for Class-Loader
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: Makefile.PL,v 1.1.1.1 2001/04/22 01:11:40 vipul Exp $

use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Class::Loader',
    'AUTHOR'       => 'Vipul Ved Prakash <mail@vipul.net>',
    'VERSION_FROM' => 'lib/Class/Loader.pm',
);

