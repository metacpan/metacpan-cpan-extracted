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
use Test::Vars;

if ($] >= 5.022) {
	plan skip_all => "Test::Vars is buggy on 5.22";
}
all_vars_ok ();
