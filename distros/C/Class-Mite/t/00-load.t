#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Role') || print "Bail out!\n"; }

diag( "Testing Role $Role::VERSION, Perl $], $^X" );
