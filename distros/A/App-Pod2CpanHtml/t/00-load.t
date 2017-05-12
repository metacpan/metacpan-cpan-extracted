#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::Pod2CpanHtml' );
}

diag( "Testing App::Pod2CpanHtml $App::Pod2CpanHtml::VERSION, Perl $], $^X" );
