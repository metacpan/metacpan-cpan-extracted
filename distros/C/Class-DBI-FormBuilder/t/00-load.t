use Test::More tests => 1;

use base 'Class::Data::Inheritable';

BEGIN {
use_ok( 'Class::DBI::FormBuilder' );
}

diag( "Testing Class::DBI::FormBuilder $Class::DBI::FormBuilder::VERSION, Perl $], $^X" );
