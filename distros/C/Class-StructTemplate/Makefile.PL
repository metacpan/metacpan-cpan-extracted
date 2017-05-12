#!/usr/bin/perl
#
# Makefile.PL - Makefile for installing Class::StructTemplate and Class::Persistent::StructTemplate
#
# Copyright (C) 2000 by Heiko Wundram.
# All rights reserved.
#
# This program is free software; you can redistribute and/or modify it under the same terms as Perl itself.
#

use ExtUtils::MakeMaker;

WriteMakefile( 'NAME' => 'Class::StructTemplate',
	       'VERSION_FROM' => './lib/Class/StructTemplate.pm',
	       'AUTHOR' => 'Heiko Wundram <ceosg@t-online.de>',
	       'ABSTRACT' => 'Implementation of a serializable Class::Struct',
	       'PREREQ_PM' => {
		   'DBI' => 0,
		   'Exporter' => 0,
	       } );
