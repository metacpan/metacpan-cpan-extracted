use Test::More tests => 1;

use base 'Class::DBI';

BEGIN {
use_ok( 'Class::DBI::Cascade::Plugin::Nullify' );
}

diag( "Testing Class::DBI::Cascade::Plugin::Nullify $Class::DBI::Cascade::Plugin::Nullify::VERSION, Perl 5.008006, /usr/local/bin/perl" );
