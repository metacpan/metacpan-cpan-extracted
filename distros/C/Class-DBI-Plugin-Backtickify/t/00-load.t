use Test::More tests => 1;

use base 'Class::DBI';

BEGIN {
use_ok( 'Class::DBI::Plugin::Backtickify' );
}

diag( "Testing Class::DBI::Plugin::Backtickify $Class::DBI::Plugin::Backtickify::VERSION, Perl 5.008006, /usr/local/bin/perl" );
