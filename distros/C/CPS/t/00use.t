#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok( 'CPS' );
use_ok( 'CPS::Functional' );

use_ok( 'CPS::Governor' );

use_ok( 'CPS::Governor::Simple' );
use_ok( 'CPS::Governor::Deferred' );

done_testing;
