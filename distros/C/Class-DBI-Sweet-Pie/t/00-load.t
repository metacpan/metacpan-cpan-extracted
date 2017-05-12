#!perl -T

use Test::More tests => 1;

BEGIN {
    require_ok( 'Class::DBI::Sweet::Pie' );
}

diag( "Testing Class::DBI::Sweet::Pie $Class::DBI::Sweet::Pie::VERSION, Perl $], $^X" );

