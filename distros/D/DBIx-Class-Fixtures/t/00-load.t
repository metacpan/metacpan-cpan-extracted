use Test::More tests => 1;

BEGIN {
	use_ok( 'DBIx::Class::Fixtures' ) or BAIL_OUT($@);
}

diag( "Testing DBIx::Class::Fixtures $DBIx::Class::Fixtures::VERSION, Perl $], $^X" );
