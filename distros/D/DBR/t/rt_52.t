#!/usr/bin/perl

use strict;
use warnings;
no warnings 'uninitialized';

$| = 1;

use lib './lib';
use t::lib::Test;
use Test::More tests => 5;

my $dbr = setup_schema_ok('rt_52');

my $dbrh = $dbr->connect('rt_52');
ok($dbrh, 'dbr connect');
my $rv;

ok( $dbrh->test->where(status => undef     )->count == 1,'Test Null' );
ok( $dbrh->test->where(status => 'zeroness')->count == 2,'Test Zero' );
ok( $dbrh->test->where(status => 'oneness' )->count == 3,'Test One'  );
