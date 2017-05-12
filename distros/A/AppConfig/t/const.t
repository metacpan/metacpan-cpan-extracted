#!/usr/bin/perl -w

#========================================================================
#
# t/const.t 
#
# AppConfig::Const test file.
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
use Test::More tests => 9;
use AppConfig ':expand';
ok(1, 'loaded');


#------------------------------------------------------------------------
#2 - #5: test that the EXPAND_XXX constants got imported
#

ok( EXPAND_UID, 'EXPAND_UID' );
ok( EXPAND_VAR, 'EXPAND_VAR' );
ok( EXPAND_ENV, 'EXPAND_ENV' );
ok( EXPAND_ALL == EXPAND_UID | EXPAND_VAR | EXPAND_ENV, 'EXPAND_ALL' );


#------------------------------------------------------------------------
#6 - #9: test that the EXPAND_XXX package vars are defined
#

ok( AppConfig::EXPAND_UID, 'EXPAND_UID' );
ok( AppConfig::EXPAND_VAR, 'EXPAND_VAR' );
ok( AppConfig::EXPAND_ENV, 'EXPAND_ENV' );
ok( AppConfig::EXPAND_ALL == 
    AppConfig::EXPAND_UID 
  | AppConfig::EXPAND_VAR 
  | AppConfig::EXPAND_ENV, 'EXPAND_ALL' );

