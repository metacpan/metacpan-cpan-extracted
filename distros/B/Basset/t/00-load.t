#!perl -T

use Test::More tests => 15;

BEGIN {
	use_ok( 'Basset::Container::Hash' );
	use_ok( 'Basset::DB::Nontransactional' );
	use_ok( 'Basset::DB::Table::View' );
	use_ok( 'Basset::DB::Table' );
	use_ok( 'Basset::DB' );
	use_ok( 'Basset::Logger' );
	use_ok( 'Basset::Machine::State' );
	use_ok( 'Basset::Machine' );
	use_ok( 'Basset::NotificationCenter' );
	use_ok( 'Basset::Object::Conf' );
	use_ok( 'Basset::Object' );
	use_ok( 'Basset::Object::Persistent' );
	use_ok( 'Basset::Template' );
	use_ok( 'Basset::Test::More' );
	use_ok( 'Basset::Test' );
}

diag( "Testing Basset 1.0.3, Perl $], $^X" );
