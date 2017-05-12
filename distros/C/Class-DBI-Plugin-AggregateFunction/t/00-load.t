#!perl -T

use Test::More tests => 1;

BEGIN {
    require_ok( 'Class::DBI::Plugin::AggregateFunction' );
}

diag( "Testing Class::DBI::Plugin::AggregateFunction $Class::DBI::Plugin::AggregateFunction::VERSION, Perl $], $^X" );

