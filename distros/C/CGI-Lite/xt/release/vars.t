#!/usr/bin/perl
#
#===============================================================================
#
#         FILE: vars.t
#
#  DESCRIPTION: Test that there are no unused vars
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Pete Houston (), ph1@openstrike.co.uk
# ORGANIZATION: Openstrike
#      CREATED: 23/11/15 22:37:37
#===============================================================================

use strict;
use warnings;

use Test::More;
use Test::Vars 0.012;

all_vars_ok ();
