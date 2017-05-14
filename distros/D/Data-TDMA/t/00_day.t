#!/usr/bin/perl
#
#  Created by Jane A. Avriette on 2007-06-14.
#  Copyright (c) 2007. All rights reserved.
#

use warnings;
use strict;

$|++;

use Test::More qw{ no_plan };

use lib qw{ . lib };

use_ok( 'Data::TDMA' );
use Data::TDMA::Constants qw{ :all } ; # XXX: use_ok doesn't like qw{ } 
use_ok( 'Data::TDMA::Day' );
use_ok( 'Data::TDMA::Day::Epoch' );
use_ok( 'Data::TDMA::Day::Epoch::Frame' );
use_ok( 'Data::TDMA::Day::Epoch::Frame::Slot' );

use Time::HiRes;

my $delta;
my $now = time();

warn "\nThis may take a while.\n";
ok(
	my $day = Data::TDMA::Day->new( {
			zeroh  => time(), 
			omegah => time() + 86400
		}
	)
);

$delta = time() - $now;
diag( "Your first test, with specified parameters, took $delta seconds." );

ok( $delta > 0 );

warn "\nThis, too, may take a while.\n";

$now = time();
ok( $day = Data::TDMA::Day->new( {} ) );
$delta = time() - $now;
diag( "The arbitrarily constructed day took $delta seconds to complete." );
diag( "Nominally this would take place in 1/32 of a second, or .031s." );
diag( "Which is why $ is probably not fast enough for this." );

ok( $delta > 0 );

exit 0;

# jaa // vim: ts=2
