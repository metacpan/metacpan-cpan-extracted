#!/usr/bin/perl -w
# $Id: 01compile.t 1509 2010-08-21 23:10:21Z ian $

# compile.t
#
# Ensure the module compiles.

use strict;
use Test::More tests => 1;

# make sure the module compiles
BEGIN{ use_ok( 'Class::Declare' ) }
