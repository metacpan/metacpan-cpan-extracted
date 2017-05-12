#!/usr/bin/env perl
use lib 'lib';
use Test::More tests => 3;
use_ok( 'CPAN::Source' );
use_ok( 'CPAN::Source::Dist' );
use_ok( 'CPAN::Source::Package' );
