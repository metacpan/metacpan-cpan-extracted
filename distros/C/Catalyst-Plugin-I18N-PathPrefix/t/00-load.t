#!/usr/bin/env perl -T

use strict;
use warnings;

use Test::Most tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::I18N::PathPrefix' );
}

diag( "Testing Catalyst::Plugin::I18N::PathPrefix $Catalyst::Plugin::I18N::PathPrefix::VERSION, Perl $], $^X" );
