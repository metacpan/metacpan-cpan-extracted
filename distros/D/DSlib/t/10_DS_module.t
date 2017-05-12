#!/usr/bin/perl

# ########################################################################## #
# Title:         Build time tests of DS.pm
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Runs tests of DS.pm
# File:          $Source: /data/cvs/lib/DSlib/t/10_DS_module.t,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
        $|  = 1;
        $^W = 1;
}

use_ok( 'DS' );
ok( $DS::VERSION =~ /^\d[[:digit:]\.]*\d$/ ) or diag("Version string missing or invalid: ${DS::VERSION}");
