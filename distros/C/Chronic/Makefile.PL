#!/usr/bin/perl -s
##
## Makefile for Chronic
##
## Copyright (c) 2004, Vipul Ved Prakash <mail@vipul.net>
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: Makefile.PL,v 1.3 2004/08/15 21:00:06 hackworth Exp $

use ExtUtils::MakeMaker;

WriteMakefile (

    DISTNAME      => 'Chronic',
    NAME          => 'Chronic',
    AUTHOR        => 'Vipul Ved Prakash <mail@vipul.net>',
    ABSTRACT      => 'Constraints-based, opportunistic scheduler.',
    DISTNAME      => 'Chronic', 
    VERSION_FROM  => 'VERSION',
    EXE_FILES     => [ qw( chronicd emerge-later ) ], 
	MAN1PODS      => { 
                       'docs/chronicd.pod'      => '$(INST_MAN1DIR)/chronicd.1',
                       'docs/emerge-later.pod'  => '$(INST_MAN1DIR)/emerge-later.1',
                     },

);

