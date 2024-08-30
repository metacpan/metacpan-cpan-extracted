package Dancer2::Session::DBI;

use 5.006;
use strict;
use warnings;

use Moo;
use JSON;
use DBI;
use Carp qw( carp croak );

=encoding utf8

=head1 NAME

Dancer2::Session::DBI - DBI based session engine for Dancer

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.0.1';


=head1 SYNOPSIS

This is a more or less faithful port of L<Dancer::Session::DBI> to L<Dancer2>.
It implements a session engine by serializing the session and storing it
in a database via L<DBI>. The only supported serialization method is L<JSON>.

This was, so far, only tested with PostgreSQL but should in theory work
with MySQL and SQLite as well, as we inherit the handling of these databases
from the original module.

=head1 USAGE

In config.yml

	session: 'DBI'
	engines:
		session:
			DBI:
			dsn: "dbi:Pg:dbname=testing;host=127.0.0.1"
			dbtable: "sessions"
			dbuser: "user"
			dbpass: "password"

The table needs to have at least C<id> and a C<session_data> columns.

A timestamp field that updates when a session is updated is recommended, so you can
expire sessions server-side as well as client-side.

This session engine will not automagically remove expired sessions on the server,
but with a timestamp field as above, you should be able to do it manually.

=cut

with 'Dancer2::Core::Role::SessionFactory';

has dsn => (
	is => 'ro',
	required => 1,
);

has dbuser => (
	is => 'rw',
);
has dbpass => (
	is => 'rw',
);
has dbtable => (
	is => 'rw',
	required => 1,
);

has quoted_table => (
	is => 'ro',
	builder => '_build_quoted_table'
);

sub _build_quoted_table {
	my $self = shift;

	return $self->dbh->quote_identifier( $self->{dbtable} );
};


has dbh => (
	is => 'rw',
	lazy => 1,
	builder => '_build_dbh',
);

sub _build_dbh {
	my ($self) = @_;

	DBI->connect($self->dsn, $self->dbuser, $self->dbpass);
}





sub _retrieve {
	my ($self, $session_id) = @_;

	my $quoted_table = $self->quoted_table;

	my $sth = $self->dbh->prepare("select session_data from $quoted_table where id=?");
	$sth->execute($session_id);
	my ($json) = $sth->fetchrow_array();

	# Bail early if we know we have no session data at all
	if (!defined $json) {
		carp("Could not retrieve session ID: $session_id");
		return;
	}

	# No way to check that it's valid JSON other than trying to deserialize it
	my $session = from_json($json);

	return bless $session, 'Dancer::Core::Session';
}


sub _flush {
	my ($self, $id, $data) = @_;
	my $json = to_json( { %{ $data } } );

    my $quoted_table = $self->quoted_table;

	# There is no simple cross-database way to do an "upsert"
	# without race-conditions. So we will have to check what database driver
	# we are using, and issue the appropriate syntax.
	my $driver = lc $self->dbh->{Driver}{Name};

	if ($driver eq 'mysql') {

		# MySQL 4.1.1 made this syntax actually work. Best be extra careful
		if ($self->dbh->{mysql_serverversion} < 40101) {
			die "A minimum of MySQL 4.1.1 is required";
		}

		my $sth = $self->dbh->prepare(qq{
			INSERT INTO $quoted_table (id, session_data)
			VALUES (?, ?)
			ON DUPLICATE KEY
			UPDATE session_data = ?
		});

		$sth->execute($id, $json, $json);

	} elsif ($driver eq 'sqlite') {

		# All stable versions of DBD::SQLite use an SQLite version that support upserts
		my $sth = $self->dbh->prepare(qq{
			INSERT OR REPLACE INTO $quoted_table (id, session_data)
			VALUES (?, ?)
		});

		$sth->execute($id, $json);
		$self->dbh->commit() unless $self->dbh->{AutoCommit};

	} elsif ($driver eq 'pg') {

		# Upserts need writable CTE's, which only appeared in Postgres 9.1
		if ($self->dbh->{pg_server_version} < 90100) {
			die "A minimum of PostgreSQL 9.1 is required";
		}

		my $sth = $self->dbh->prepare(qq{
			WITH upsert AS (
				UPDATE $quoted_table
				SET session_data = ?
				WHERE id = ?
				RETURNING id
			)

			INSERT INTO $quoted_table (id, session_data)
			SELECT ?, ?
			WHERE NOT EXISTS (SELECT 1 FROM upsert);
		});

		$sth->execute($json, $id, $id, $json);
		$self->_dbh->commit() unless $self->dbh->{AutoCommit};

	} else {

		die "SQLite, MySQL > 4.1.1, and PostgreSQL > 9.1 are the only supported databases";

	}
}


sub _destroy {
    my ($self, $session_id) = @_;

	if (!defined $session_id) {
		carp("No session ID passed to destroy method");
		return;
	}

	my $quoted_table = $self->quoted_table;

	my $sth = $self->dbh->prepare(qq{
		DELETE FROM $quoted_table
		WHERE id = ?
	});

	$sth->execute($session_id);
}


sub _sessions {
	my ($self) = @_;


	my $quoted_table = $self->quoted_table;

	my $sth = $self->dbh->prepare(qq{
		SELECT id FROM $quoted_table
	});

	$sth->execute();

	return $sth->fetchall_arrayref();
}


=head1 SEE ALSO

L<Dancer2>, L<Dancer2::Session>, L<Dancer::Session>

=head1 ACKNOWLEDGEMENTS

This module is based on Dancer::Session::DBI by James Aitken <jaitken@cpan.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Dennis Lichtenthäler.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Dancer2::Session::DBI
