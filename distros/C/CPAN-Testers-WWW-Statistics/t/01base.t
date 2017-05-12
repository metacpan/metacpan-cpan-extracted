#!/usr/bin/perl -w
use strict;

use Test::More tests => 4;

BEGIN {
	use_ok( 'CPAN::Testers::WWW::Statistics' );
	use_ok( 'CPAN::Testers::WWW::Statistics::Graphs' );
	use_ok( 'CPAN::Testers::WWW::Statistics::Pages' );
	use_ok( 'CPAN::Testers::WWW::Statistics::Leaderboard' );
}
