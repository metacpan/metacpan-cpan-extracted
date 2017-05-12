#!/usr/bin/perl

use strict;

$| = 1;

use lib './lib';
use t::lib::Test;
use Test::More tests => 10;
use DBR::Config::Scope;
use DBR::Util::Operator;

my $dbr = setup_schema_ok( 'rt_54' );

my $dbrh = $dbr->connect( 'rt_54' );
ok($dbrh, 'dbr connect');

# 2 tests so far, plus tests below

my $recs;

$recs = $dbrh->abc->where( status => 'one' );
ok( $recs, 'get recs A' );
ok( $recs->count == 1, 'Count A');

$recs = $dbrh->abc->where( status => NOT 'one' );
ok( $recs, 'get recs B' );
ok( $recs->count == 2, 'Count B');

$recs = $dbrh->abc->where( status => 'one two' );
ok( $recs, 'get recs C' );
ok( $recs->count == 2, 'Count C');

$recs = $dbrh->abc->where( status => NOT 'one two' );
ok( $recs, 'get recs D' );
ok( $recs->count == 1, 'Count D');

1;

