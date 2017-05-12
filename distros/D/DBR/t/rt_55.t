#!/usr/bin/perl

use strict;

$| = 1;

use lib './lib';
use t::lib::Test;
use Test::More tests => 3;
use DBR::Config::Scope;
use DBR::Util::Operator;

my $dbr = setup_schema_ok( 'rt_55' );

my $dbrh = $dbr->connect( 'rt_55' );
ok($dbrh, 'dbr connect');

# 2 tests so far, plus tests below

my $recs;

my $new_id = $dbrh->abc->insert( status => 'one', name => 'added' );
ok( $new_id, 'new id from insert' );

1;

