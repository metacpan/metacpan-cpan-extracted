#!/usr/bin/perl -w
# $Id: 11export.t 1515 2010-08-22 14:41:53Z ian $

# export.t
#
# Ensure the symbol exports from Class::Declare are honoured.

use strict;
use Test::More	tests	=> 1;

# make sure we can import the read-write and read-only modifiers
BEGIN { use_ok( 'Class::Declare::Attributes' , qw( :modifiers ) ) };
