use strict;
use Test::More;

BEGIN {
	eval 'use DBD::SQLite; use SQL::Abstract';
	plan $@
		? ( skip_all => 'needs DBD::SQLite and SQL::Abstract for testing' )
		: ( tests => 1 );
}

use DBI;

my $db = 't/testdb';
my @dsn = ( "dbi:SQLite:dbname=$db", "", "", { autoCommit => 1 } );
DBI->connect( @dsn)->do( <<"" );
CREATE TABLE music
( id INTEGER NOT NULL PRIMARY KEY
, title VARCHAR(32)
)

{
	package Class::DBI::Plugin::AbstractCount;
	use base 'Class::DBI::Plugin';
	use SQL::Abstract;
	sub init {
		$_[0]->set_sql( count_search_where => "SELECT COUNT(*) FROM __TABLE__ %s" );
	}
	sub count_search_where : Plugged {
		my $class = shift;
		my ( $phrase, @bind ) = SQL::Abstract->new()->where( { @_ } );
		$class->sql_count_search_where( $phrase )->select_val( @bind );
	}
}

{
	package Music;
	use base qw( Class::DBI );
	__PACKAGE__->set_db( Main => @dsn );
	__PACKAGE__->table( 'music' );
	__PACKAGE__->columns( Primary => qw( id ) );
	__PACKAGE__->columns( All => qw( title ) );
	Class::DBI::Plugin::AbstractCount->import;
}

for my $i ( 1 .. 50 ) {
	Music->create(
	{ title => "title $i"
	});
}

my $count = Music->count_search_where( title => [ 'title 10', 'title 20' ] );
is $count, 2, "count is 2";

END { unlink $db if -e $db }

