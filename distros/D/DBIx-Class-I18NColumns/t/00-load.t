#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'DBIx::Class::I18NColumns' );
}

diag( "Testing DBIx::Class::I18NColumns $DBIx::Class::I18NColumns::VERSION, Perl $], $^X" );
