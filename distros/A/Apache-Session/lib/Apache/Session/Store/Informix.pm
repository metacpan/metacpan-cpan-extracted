#############################################################################
#
# Apache::Session::Store::Informix
# Implements session object storage via Informix
# Copyright(c) 1998, 1999, 2000, 2004 Jeffrey William Baker (jwbaker@acm.org) and Mike Langen (mike.langen@tamedia.ch)
# Distribute under the Perl License
#
############################################################################

package Apache::Session::Store::Informix;

use strict;

use DBI;
use Apache::Session::Store::DBI;

use vars qw(@ISA $VERSION);

@ISA = qw(Apache::Session::Store::DBI);
$VERSION = '1.02';

$Apache::Session::Store::Informix::DataSource = undef;
$Apache::Session::Store::Informix::UserName   = undef;
$Apache::Session::Store::Informix::Password   = undef;

sub connection {
    my $self    = shift;
    my $session = shift;
    
    return if (defined $self->{dbh});

    if (exists $session->{args}->{Handle}) {
        $self->{dbh} = $session->{args}->{Handle};
        $self->{commit} = $session->{args}->{Commit};
        return;
    }

    my $datasource = $session->{args}->{DataSource} || 
        $Apache::Session::Store::Informix::DataSource;
    my $username = $session->{args}->{UserName} ||
        $Apache::Session::Store::Informix::UserName;
    my $password = $session->{args}->{Password} ||
        $Apache::Session::Store::Informix::Password;
        
    $self->{dbh} = DBI->connect(
        $datasource,
        $username,
        $password,
        { RaiseError => 1, AutoCommit => 0 }
    ) || die $DBI::errstr;

    
    #If we open the connection, we close the connection
    $self->{disconnect} = 1;
    
    #the programmer has to tell us what commit policy to use
    $self->{commit} = $session->{args}->{Commit};
}

sub materialize {
    my $self    = shift;
    my $session = shift;

    $self->connection($session);

    local $self->{dbh}->{RaiseError}  = 1;
    local $self->{dbh}->{LongReadLen} = $session->{args}->{LongReadLen} || 8*2**10;
    
    if (!defined $self->{materialize_sth}) {
        $self->{materialize_sth} = 
            $self->{dbh}->prepare_cached(qq{
                SELECT a_session FROM sessions WHERE id = ? FOR UPDATE});
    }
    
    $self->{materialize_sth}->bind_param(1, $session->{data}->{_session_id});
    $self->{materialize_sth}->execute;
    
    my $results = $self->{materialize_sth}->fetchrow_arrayref;

    if (!(defined $results)) {
        die "Object does not exist in the data store";
    }

    $self->{materialize_sth}->finish;

    $session->{serialized} = $results->[0];
}

sub DESTROY {
    my $self = shift;

    if ($self->{commit}) {
        $self->{dbh}->commit;
    }
    
    if ($self->{disconnect}) {
        $self->{dbh}->disconnect;
    }
}

1;

=pod

=head1 NAME

Apache::Session::Store::Informix - Store persistent data in a Informix database

=head1 SYNOPSIS

 use Apache::Session::Store::Informix;

 my $store = new Apache::Session::Store::Informix;

 $store->insert($ref);
 $store->update($ref);
 $store->materialize($ref);
 $store->remove($ref);

=head1 DESCRIPTION

Apache::Session::Store::Informix fulfills the storage interface of
Apache::Session. Session data is stored in a Informix database.

=head1 SCHEMA

To use this module, you will need at least these columns in a table 
called 'sessions':

 id char(32)     # or however long your session IDs are.
 a_session lvarchar

To create this schema, you can execute this command using the sqlplus program:

 CREATE TABLE sessions (
    id char(32) not null primary key,
    a_session lvarchar
 );

If you use some other command, ensure that there is a unique index on the
table's id column.

=head1 CONFIGURATION

The module must know what datasource, username, and password to use when
connecting to the database.  These values can be set using the options hash
(see Apache::Session documentation).  The options are DataSource, UserName,
and Password.

Example:

 tie %hash, 'Apache::Session::Informix', $id, {
     DataSource => 'dbi:Informix:database',
     UserName   => 'database_user',
     Password   => 'K00l'
 };

Instead, you may pass in an already-opened DBI handle to your database.

 tie %hash, 'Apache::Session::Informix', $id, {
     Handle => $dbh
 };

The last option is LongReadLen, which specifies the maximum size of the session
object.  If not supplied, the default maximum size is 8 KB.

=head1 AUTHOR

This module was written by Mike Langen <mike.langen@tamedia.ch>, based
on the original for Oracle.

=head1 SEE ALSO

L<Apache::Session>, L<Apache::Session::Store::DBI>
