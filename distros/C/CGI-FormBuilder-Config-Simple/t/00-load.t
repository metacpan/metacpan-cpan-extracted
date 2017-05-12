#!perl -T

use Test::More tests => 1;

use lib qw( lib );

BEGIN {
    use_ok( 'CGI::FormBuilder::Config::Simple' );
}

diag( "Testing CGI::FormBuilder::Config::Simple $CGI::FormBuilder::Config::Simple::VERSION, Perl $], $^X" );
