#!/usr/bin/env perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Catalyst::Plugin::Widget' );
}

diag( "Testing Catalyst::Plugin::Widget $Catalyst::Plugin::Widget::VERSION, Perl $], $^X" );

