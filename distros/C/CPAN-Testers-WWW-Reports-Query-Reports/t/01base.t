#!/usr/bin/perl -w
use strict;

use lib qw(./lib);
use Test::More tests => 1;

BEGIN {
	use_ok( 'CPAN::Testers::WWW::Reports::Query::Reports' );
}
