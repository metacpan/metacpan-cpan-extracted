#!perl -T

use Test::More tests => 15;

BEGIN {
	use_ok( 'DBIx::DataModel', -compatibility => undef );
	use_ok( 'DBIx::DataModel::Meta' );
	use_ok( 'DBIx::DataModel::Meta::Association' );
	use_ok( 'DBIx::DataModel::Meta::Path' );
	use_ok( 'DBIx::DataModel::Meta::Schema' );
	use_ok( 'DBIx::DataModel::Meta::Source' );
	use_ok( 'DBIx::DataModel::Meta::Type' );
	use_ok( 'DBIx::DataModel::Meta::Utils' );
	use_ok( 'DBIx::DataModel::Schema' );
	use_ok( 'DBIx::DataModel::Schema::Generator' );
	use_ok( 'DBIx::DataModel::Source' );
	use_ok( 'DBIx::DataModel::Source::Join' );
	use_ok( 'DBIx::DataModel::Source::Table' );
	use_ok( 'DBIx::DataModel::Statement' );
	use_ok( 'DBIx::DataModel::Statement::JDBC' );
	# use_ok( 'DBIx::DataModel::Statement::Oracle' );
        # (tested in v2_Oracle.t)
}

diag( "Testing DBIx::DataModel $DBIx::DataModel::VERSION, Perl $], $^X" );
