#!/usr/bin/perl -Tw
# $Id: 01compile.t 1515 2010-08-22 14:41:53Z ian $

# compile.t
#
# Ensure the module compiles.

use strict;
use Test::More tests => 1;

# make sure the module compiles
BEGIN{ use_ok( 'Class::Declare::Attributes' ) }
