#!/usr/bin/perl

use Test::More tests => 5;

use_ok( 'CPS' );
use_ok( 'CPS::Functional' );

use_ok( 'CPS::Governor' );

use_ok( 'CPS::Governor::Simple' );
use_ok( 'CPS::Governor::Deferred' );
