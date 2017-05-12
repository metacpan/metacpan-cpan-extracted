#!/usr/bin/env perl -T

use strict;
use warnings;

use Test::Most tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::SpecialAction::Trail' );
}

diag( "Testing Catalyst::Plugin::SpecialAction::Trail $Catalyst::Plugin::SpecialAction::Trail::VERSION, Perl $], $^X" );
