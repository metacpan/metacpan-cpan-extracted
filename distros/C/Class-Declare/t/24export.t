#!/usr/bin/perl -w
# $Id: 24export.t 1511 2010-08-21 23:24:49Z ian $

# export.t
#
# Ensure the symbol exports from Class::Declare are honoured.

use strict;
use Test::More  tests => 1;

# make sure we can import the read-write and read-only modifiers
BEGIN { use_ok( 'Class::Declare' , qw( :modifiers ) ) };
