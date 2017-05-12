#
#    DBIBase64Store.pm - Session store implemented with DBI database.
#
#    This file is part of Apache::iNcom.
#
#    Author: Francis J. Lacoste <francis.lacoste@iNsu.COM>
#    Based on Apache::Session:DBIStore from Jeffrey William Baker
#
#    Copyright (C) 1999 Francis J. Lacoste, iNsu Innovations
#    Parts Copyright(c) 1998, 1999 Jeffrey William Baker (jeffrey@kathyandjeffrey.net)
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms same terms as perl itself.
#

package Apache::Session::DBIBase64Store;

use strict;

use DBI;
use Storable qw( nfreeze thaw );
use MIME::Base64;

use vars qw($VERSION);

BEGIN {
    ($VERSION) = '$Revision: 1.2 $' =~ /Revision: ([\d.]+)/ ;
}

sub new {
    my $class = shift;

    return bless {}, $class;
}

sub get_handle {
    my ($self,$session) = @_;

    my $dbh = $session->{args}{dbh} || $self->{dbh};
    unless ( $dbh ) {
	my $dsn		= $session->{args}{DataSource};
	my $username	= $session->{args}{UserName};
	my $password	= $session->{args}{Password};

	die "No opened database connection and no DSN\n" unless $dsn;
	$dbh = DBI->connect( $dsn, $username, $password, { AutoCommit => 0,
							   RaiseError => 1,
							 } );

	# Save it for future use
	$self->{dbh}   = $dbh;
    }
    die "No opened database connection\n" unless $dbh;

    return $dbh;
}

sub insert {
    my $self    = shift;
    my $session = shift;

    my $dbh = $self->get_handle( $session );

    my $sth =$dbh->prepare(qq{ INSERT INTO sessions (id, created, last_update,
						     length, a_session)
			   	    VALUES (?,'now()', 'now()', ?, ? ) } );

    my $serialized = encode_base64( nfreeze $session->{data} );

    $sth->execute ( $session->{data}{_session_id}, length $serialized,
		    $serialized );
    $sth->finish;
    $dbh->commit;
}


sub update {
    my $self    = shift;
    my $session = shift;

    my $dbh = $self->get_handle( $session );

    my $sth = $dbh->prepare( qq{ UPDATE sessions
				    SET length = ?, a_session = ?,
					last_update = now()
				  WHERE id = ?} );

    my $serialized = encode_base64( nfreeze $session->{data} );

    $sth->execute( length $serialized, $serialized,
		   $session->{data}{_session_id} );
    $sth->finish;
    $dbh->commit;
}

sub materialize {
    my $self    = shift;
    my $session = shift;

    my $dbh = $self->get_handle( $session );

    my $sth = $dbh->prepare( qq{ SELECT a_session FROM sessions WHERE id = ?});
    $sth->execute( $session->{data}{_session_id} );

    my $results = $sth->fetchrow_arrayref;
    die "Object does not exist in the data store" unless defined $results;

    $sth->finish;

    $session->{data} = thaw decode_base64( $results->[0] );

    die "Session is corrupted\n" unless $session->{data};

    $dbh->commit;
}

sub remove {
    my $self    = shift;
    my $session = shift;

    my $dbh = $self->get_handle( $session );

    my $sth = $dbh->prepare( qq{ DELETE FROM sessions WHERE id = ?} );
    $sth->execute( $session->{data}{_session_id} );
    $sth->finish;

    $dbh->commit;
}

sub DESTROY {
    my $self = shift;

    if ( $self->{dbh} ) {
	# Close connection to the database if we opened
	# it. If it is not ours, it is up to the owner
	# to dispose of it.
	$self->{dbh}->disconnect;
    }
}

1;
__END__

=pod

=head1 NAME

Apache::Session::DBIBase64Store - Session persistence via DBI with  ASCII 
encoding of session data.

=head1 SYNOPSIS

    package MySession;

    use Apache::Session;
    use Apache::Session::DBIBase64Store;
    use Apache::Session::NullLocker;

    @ISA = ( Apache::Session );

    sub get_object_store {
	my $self = shift;

	return new Apache::Session::DBIBase64Store $self;
    }

    sub get_lock_manager {
	my $self = shift;

	return new Apache::Session::NullLocker $self;
    }

=head1 DESCRIPTION

Apache::Session::DBIBase64Store is a session data persistent store for
L<Apache::Session|Apache::Session>. This module should be used instead
of DBIStore in database that don't support binary data in table fields
(like PostgreSQL for instance).

This store also store the creation time of the session and the timestamp
of the last update.

=head1 SCHEMA

This modules expect a table created with the following schema :

    CREATE TABLE sessions (
	id	    CHAR(32) PRIMARY KEY,
	length	    INT,
	a_session   TEXT,
	created	    TIMESTAMP DEFAULT 'now()',
	last_update TIMESTAMP DEFAULT 'now()'
	locked_by   INT
    );


The previous SQL statement is valid for PostgreSQL. Adapt for your
specific DBMS.

NOTE: The id length can be fine tuned for specific application. By
default, L<Apache::Session|Apache::Session> uses 16 char length ID,
but I usually use 128 bits ID (32 chars).

=head1 CONFIGURATION

This package can either use an already open DBH handle or it can
be told the DataSource, UserName and Password to open its own database
connection.

In the first case use something like this (using the
L<SYNOPSIS|/SYNOPSIS> example):

    my $dbh = DBI->connect( $DSN, $USER, $PASSWORD, { AutoCommit => 0,
						      RaiseError => 1,} );
    tie %sesssion, 'MySession', undef, { dbh => $dbh };

In the second case use something like this :

    tie %session, 'MySession', undef, { DataSource => $DSN,
					UserName   => $USERNAME,
					Password   => $PASSWORD,
    				        };

In the case where you give this module a DBH handle to use, rather
than to manage its own. The module will commit the transaction after
each insert, update or delete. Be warned if you are not using
AutoCommit mode.

=head1 CREDITS

This module is largely based on
L<Apache::Session::DBIStore|Apache::Session::DBIStore> by Jeffrey
William Baker (jeffrey@kathyandjeffrey.net).

=head1 AUTHOR

Copyright (c) 1999 Francis J. Lacoste and iNsu Innovations Inc.
All rights reserved.

Parts Copyright (c) 1998,1999 Jeffrey William Baker
(jeffrey@kathyandjeffrey.net)

This program is free software; you can redistribute it and/or modify
it under the terms as perl itself.

=head1 SEE ALSO

Apache::Session(3) Apache::Session::DBIStore(3) DBI(3)

=cut


