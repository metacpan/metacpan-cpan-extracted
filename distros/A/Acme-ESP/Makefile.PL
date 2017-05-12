#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'              => 'Acme::ESP',
    'VERSION_FROM'      => 'ESP.pm',
    (  $] < 5.005  ?  ()  :
    ( 'AUTHOR'          => 'Tye McQueen',
      'ABSTRACT_FROM'   => 'ESP.pm' )
    ),
);
