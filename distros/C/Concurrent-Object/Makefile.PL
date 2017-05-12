#!/usr/bin/perl -sw
##
## Makefile.PL for Concurrent::Object
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: Makefile.PL,v 1.5 2001/06/20 20:20:39 vipul Exp $ 

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Concurrent::Object',
    'AUTHOR'       => 'Vipul Ved Prakash <mail@vipul.net>',
    'VERSION_FROM' => 'lib/Concurrent/Object.pm',
    'PREREQ_PM'    => { 
                        Data::Dumper  => 0,
                        Storable      => 0, 
                        MIME::Base64  => 0,
                        Class::Loader => '2.00',
                       },
);

