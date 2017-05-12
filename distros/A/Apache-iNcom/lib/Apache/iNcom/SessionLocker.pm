#
#    SessionLocker.pm - Manage session's lock for iNcom.
#
#    This file is part of Apache::iNcom.
#
#    Author: Francis J. Lacoste <francis.lacoste@iNsu.COM>
#
#    Copyright (C) 2000 Francis J. Lacoste, iNsu Innovations
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms same terms as perl itself.
#

package Apache::iNcom::SessionLocker;

use strict;

use DBI;

use vars qw($VERSION);

use constant MAX_TRIES => 5;

BEGIN {
    ($VERSION) = '$Revision: 1.1 $' =~ /Revision: ([\d.]+)/ ;
}

sub new {
    my $class = shift;

    my $x = 0;

    return bless \$x, $class;
}

sub acquire_read_lock {
    acquire_lock( @_ );
}

sub acquire_write_lock {
    acquire_lock( @_ );
}

sub release_read_lock {
    my ( $self ) = @_;

    return unless $$self;
    return if --$$self;

    release_lock( @_ );
}

sub release_write_lock {
    my ( $self ) = @_;

    return unless $$self;
    return if --$$self;

    release_lock( @_ );
}

sub release_all_locks {
    my ( $self ) = @_;

    return unless $$self;

    release_lock( @_ );
}

sub release_lock {
    my ( $self, $session ) = @_;

    return unless $session->{args}{Serialize};

    my $dbh = $session->{args}{dbh}
      or die "No opened database connection\n";

    my $sth =$dbh->prepare( qq{ UPDATE sessions SET locked_by = NULL
				 WHERE id = ? AND locked_by = ? } );

    $sth->execute( $session->{data}{_session_id}, $$ );
    $sth->finish;
    $dbh->commit;
}

sub acquire_lock {
    my ( $self, $session ) = @_;

    return unless $session->{args}{Serialize};

    # No need for lock in new session
    return if $session->is_new;

    # Only need one database lock
    return if $$self++;

    my $dbh = $session->{args}{dbh}
      or die "No opened database connection\n";

    my $sth =$dbh->prepare( qq{ UPDATE sessions SET locked_by = ?
				 WHERE id = ? AND locked_by IS NULL } );

    my $sel_sth =$dbh->prepare( qq{ SELECT id FROM sessions
				    WHERE id = ? AND locked_by = ? } );

    my $try	= 0;
    my $success = 0;
    while ( ! $success ) {
	if ( $sth->execute( $$, $session->{data}{_session_id} ) ) {
	    $dbh->commit;
	    # Make sure that we have the lock
	    $sel_sth->execute( $session->{data}{_session_id}, $$ );

	    my $results = $sel_sth->fetchrow_arrayref;
	    $success = defined $results;
	}
	last if $success;

	die "Time out while waiting for session lock\n"
	  if ( $try++ > MAX_TRIES );
	sleep 1;
    }
    $sth->finish;
    $sel_sth->finish;
}

1;
__END__

=pod

=head1 NAME

Apache::iNcom::SessionLocker - Manage locks for iNcom's sessions.


=head1 SYNOPSIS

    package MySession;

    sub get_lock_manager {
	my $self = shift;

	return new Apache::iNcom::SessionLocker;
    }

=head1 DESCRIPTION

Apache::iNcom::SessionLocker will serialize access to the sessions if
the configuration directive INCOM_SESSION_SERIALIZE_ACCESS is set.

A maximum of 5 seconds is waited for lock.

=head1 SCHEMA

This modules expect a table created with the following schema :

    CREATE TABLE sessions (
	id	    CHAR(32) PRIMARY KEY,
	length	    INT,
	a_session   TEXT,
	created	    TIMESTAMP DEFAULT 'now()',
	last_update TIMESTAMP DEFAULT 'now()',
	locked_by   INT
    );

The previous SQL statement is valid for PostgreSQL. Adapt for your
specific DBMS.

=head1 AUTHOR

Copyright (c) 1999 Francis J. Lacoste and iNsu Innovations Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms as perl itself.

=head1 SEE ALSO

Apache::Session(3) Apache::Session::DBIStore(3) DBI(3)

=cut


