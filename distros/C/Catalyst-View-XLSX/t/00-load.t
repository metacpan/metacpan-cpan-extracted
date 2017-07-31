#!/usr/env perl

use Test::More tests => 2;

BEGIN {
    use_ok( 'Catalyst::View::XLSX' );
    use_ok( 'Catalyst::Helper::View::XLSX' );
}

