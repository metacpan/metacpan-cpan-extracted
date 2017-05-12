#!/usr/bin/perl -w

#========================================================================
#
# t/sys.t 
#
# AppConfig::Sys test file.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use strict;
use vars qw($loaded);
use AppConfig::Sys;
use Test::More tests => 2;

my $DEBUG = grep(/^--?d(ebug)?$/, @ARGV);

# create two alternate AppConfig::Sys objects
my $sys    = AppConfig::Sys->new();            # auto-detect
my $winsys = AppConfig::Sys->new('win32');

ok( defined $sys, 'created system object' );
ok( defined $winsys, 'created windows object' );

$sys->_dump    if $DEBUG;
$winsys->_dump if $DEBUG;

if ($DEBUG) {
    foreach my $s ($sys, $winsys) {
        print "- " x 36, "\n";
        print "          os: ", $s->os, "\n";
        print "     pathsep: ", $s->pathsep, "\n";
        print "can_getpwuid: ", $s->can_getpwuid(), "\n";
        
        if($s->can_getpwuid()) {
            print "    getpwuid: ", scalar $s->getpwuid($<), "\n";
            print "    getpwuid: ", scalar $s->getpwuid(), "\n";
        }
        else {
            print "    getpwuid not available on this platform.\n";
        }
        print "can_getpwnam: ", $s->can_getpwnam(), "\n";
        
        if($s->can_getpwnam()) {
            print "    getpwnam: ", $s->getpwnam('abw'), "\n";
            print "    getpwnam: ", $s->getpwnam(), "\n";
        }
        else {
            print "    getpwnam not available on this platform.\n";
        }
    }
}
