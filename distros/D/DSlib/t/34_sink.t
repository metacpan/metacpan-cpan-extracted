#!/usr/bin/perl

# ########################################################################## #
# Title:         Build time tests of DS/Target/Sink.pm
# Creation date: 2007-04-16
# Author:        Michael Zedeler
# Description:   Runs tests of DS/Target/Sink.pm
# File:          $Source: /data/cvs/lib/DSlib/t/34_sink.t,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
        $|  = 1;
        $^W = 1;
}

use_ok( 'DS::Target::Sink' );

my $sink = new DS::Target::Sink();
ok( $sink );

# Shouldn't be possible to call importer without target
my $result = 1;
eval {
    $result = $sink->receive_row( {} );
};
ok( not defined( $@ ) or $@ eq '');
is( $result, undef );


