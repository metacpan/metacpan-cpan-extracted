package CGI::Session::SQLite;

#
# $Id: SQLite.pm,v 1.7 2004/10/21 23:10:32 bmoyles Exp $
#

use strict;
use base qw(
    CGI::Session
    CGI::Session::ID::MD5
    CGI::Session::Serialize::Default
);


# Load neccessary libraries below

our($VERSION, $TABLE_NAME);

$VERSION = '1.0';
$TABLE_NAME = 'sessions';

sub store {
    my ($self, $sid, $options, $data) = @_;
    my $dbh = $self->SQLite_dbh($options);

    my $storable_data = $self->freeze($data);

    $dbh->do(
        ' INSERT OR REPLACE INTO ' . $TABLE_NAME . ' (id, a_session) '.
        ' VALUES( '.$dbh->quote($sid).', '.$dbh->quote($storable_data).')'
    );

    return 1;

}


sub retrieve {
    my ($self, $sid, $options) = @_;

    my $dbh = $self->SQLite_dbh($options);
    my $data;
    
    $data = $dbh->selectrow_arrayref (
        ' SELECT a_session FROM '.$TABLE_NAME.
        ' WHERE id='.$dbh->quote($sid)
    );

    return $self->thaw(@$data);

}




sub remove {
    my ($self, $sid, $options) = @_;

    my $dbh = $self->SQLite_dbh($options);
    
    $dbh->do(
        ' DELETE FROM '.$TABLE_NAME.
        ' WHERE id='.$dbh->quote($sid)
    );

    return 1;
    
}



sub teardown {
    my ($self, $sid, $options) = @_;
    
    my $dbh = $self->SQLite_dbh($options);
    
    unless ($dbh->{AutoCommit}) {
        $dbh->commit();
    }

    if ($self->{SQLite_disconnect}) {
        $dbh->disconnect();
    }
    
    return 1;

}

sub SQLite_dbh {
    my ($self, $options) = @_;

    my $args = $options->[1] || {};

    if (defined($self->{SQLite_dbh})) {
        return $self->{SQLite_dbh};
    }
    
    if (defined($args->{TableName})) {
        $TABLE_NAME = $args->{TableName};
    }

    require DBI;

    $self->{SQLite_dbh} = $args->{Handle} || DBI->connect(
        $args->{DataSource},
        $args->{User} || undef,
        $args->{Password} || undef,
        { RaiseError =>1, PrintError =>1, AutoCommit =>1 } 
    );
    $args->{Handle} or $self->{SQLite_disconnect} =1;

    return $self->{SQLite_dbh};
}


# $Id: SQLite.pm,v 1.7 2004/10/21 23:10:32 bmoyles Exp $

1;       

=pod

=head1 NAME

CGI::Session::SQLite - CGI::Session driver for SQLite

=head1 SYNOPSIS
    
    use CGI::Session::SQLite
    $session = new CGI::Session("driver:SQLite", undef, {...});

For more examples, consult L<CGI::Session> manual

=head1 DESCRIPTION

CGI::Session::SQLite is a CGI::Session driver utilizing the SQLite DBMS.
To write your own drivers for B<CGI::Session> refer to the L<CGI::Session> manual.

=head1 STORAGE

To store session data in SQLite database, you first need to create a
suitable table for it with the following command:

    CREATE TABLE sessions (
        id CHAR(32) NOT NULL UNIQUE,
        a_session TEXT NOT NULL
    );

You can also add any number of additional columns to the table, but the
above "id" and "a_session" are required.

If you want to store the session data in other table than "sessions",
before creating the session object you need to set the special variable
$CGI::Session::SQLite::TABLE_NAME to the name of the table:

    use CGI::Session;
    $CGI::Session::SQLite::TABLE_NAME = 'my_sessions';
    $session = new CGI::Session("driver:SQLite", undef, {Handle=>$dbh});

=head1 COPYRIGHT

Copyright (C) 2004 Brian Moyles <bmoyles@gmail.com>. All rights reserved.

This library is free software and can be modified and distributed under the same
terms as Perl itself. 

=head1 AUTHOR

Brian Moyles <bmoyles@gmail.com>

=head1 SEE ALSO

=over 4

=item *

L<CGI::Session|CGI::Session> - CGI::Session manual

=item *

L<CGI::Session::Tutorial|CGI::Session::Tutorial> - extended CGI::Session manual

=item *

L<CGI::Session::CookBook|CGI::Session::CookBook> - practical solutions for real life problems

=item *

B<RFC 2965> - "HTTP State Management Mechanism" found at ftp://ftp.isi.edu/in-notes/rfc2965.txt

=item *

L<CGI|CGI> - standard CGI library

=item *

L<Apache::Session|Apache::Session> - another fine alternative to CGI::Session

=back

=cut


# $Id: SQLite.pm,v 1.7 2004/10/21 23:10:32 bmoyles Exp $
