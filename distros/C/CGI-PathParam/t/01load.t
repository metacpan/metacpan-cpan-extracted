#!/usr/bin/env perl
#
# $Revision: 1.1 $
# $Source: /home/cvs/CGI-PathParam/t/01load.t,v $
# $Date: 2006/05/30 22:29:29 $
#
use strict;
use warnings;
our $VERSION = '0.01';

use blib;
use English qw(-no_match_vars);
use Test::More tests => 2;

our $WHY_SKIP_SAWAMPERSAND;

BEGIN {
    if ( $ENV{TEST_MATCH_VARS} || $ENV{TEST_ALL} ) {
        eval {
            require Devel::SawAmpersand;
            Devel::SawAmpersand->import(qw(sawampersand));
        };
        if ($EVAL_ERROR) {
            $WHY_SKIP_SAWAMPERSAND =
              'Devel::SawAmpersand required to enable this test';
        }
    }
    else {
        $WHY_SKIP_SAWAMPERSAND = 'set TEST_MATCH_VARS to enable this test';
    }

    use_ok('CGI::PathParam');
}

# run sawampersand test if Devel::SawAmpersand is installed.
SKIP: {
    if ($WHY_SKIP_SAWAMPERSAND) {
        skip $WHY_SKIP_SAWAMPERSAND, 1;
    }
    isnt( sawampersand(), 1, q{$`, $&, and $' should not appear} ); ## no critic
}
