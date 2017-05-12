#!/usr/bin/perl -w

package Local::Romani::Driver::sqlite;
use base qw(Test::Class);

use DBIx::Romani::Connection;
use DBIx::Romani::Driver::sqlite;
use Test::More;
use DBI;
use strict;

use Data::Dumper;

# utility function makes SQL out of whatever
sub generate_sql { return DBIx::Romani::Driver::sqlite->new()->generate_sql( @_ ) };

sub setup : Test(setup)
{
	my $self = shift;

	# initialize database
	my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:","","");
	$dbh->do( 'CREATE TABLE book ( book_id INTEGER PRIMARY KEY, title VARCHAR(100) )' );

	# create our connection
	my $driver = DBIx::Romani::Driver::sqlite->new();
	my $conn = DBIx::Romani::Connection->new({ dbh => $dbh, driver => $driver });
	$self->{conn} = $conn;
}

sub testGenerateId : Test(1)
{
	my $self = shift;

	my $conn  = $self->{conn};
	my $idgen = $conn->create_id_generator();

	my $dbh = $conn->get_dbh();

	my $id = undef;
	my $title = "Test";

	if ( $idgen->is_before_insert() )
	{
		$id = $idgen->get_id();
	}

	my $SQL = "INSERT INTO book VALUES ( ?, ? )";
	my $sth = $dbh->prepare( $SQL );
	$sth->execute( $id, $title );

	if ( $idgen->is_after_insert() )
	{
		$id = $idgen->get_id();
	}

	is( $id, 1 );
}

sub testEscape : Test(1)
{
	my $self = shift;

	my $result = $self->{conn}->get_driver()->escape_string( "Mama's homemade soup" );

	is ( $result, "Mama''s homemade soup" );
}

1;

