#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 1;

BEGIN { use_ok('DBIx::Class::MockData') || print "Bail out!\n"; }
diag( "Testing DBIx::Class::MockData $DBIx::Class::MockData::VERSION, Perl $], $^X" );
