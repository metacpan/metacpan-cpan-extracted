#############################################################################
#
# Apache::Session::Store::Oracle
# Implements session object storage via Oracle
# Copyright(c) 1998, 1999, 2000 Jeffrey William Baker (jwbaker@acm.org)
# Distribute under the Perl License
#
############################################################################

package Apache::Session::Store::Oracle;

use strict;

use DBI;
use Apache::Session::Store::DBI;

use vars qw(@ISA $VERSION);

@ISA = qw(Apache::Session::Store::DBI);
$VERSION = '1.10';

$Apache::Session::Store::Oracle::DataSource = undef;
$Apache::Session::Store::Oracle::UserName   = undef;
$Apache::Session::Store::Oracle::Password   = undef;

sub connection {
    my $self    = shift;
    my $session = shift;
    
    return if (defined $self->{dbh});

	$self->{'table_name'} = $session->{args}->{TableName} || $Apache::Session::Store::DBI::TableName;

    if (exists $session->{args}->{Handle}) {
        $self->{dbh} = $session->{args}->{Handle};
        $self->{commit} = $session->{args}->{Commit};
        return;
    }

    my $datasource = $session->{args}->{DataSource} || 
        $Apache::Session::Store::Oracle::DataSource;
    my $username = $session->{args}->{UserName} ||
        $Apache::Session::Store::Oracle::UserName;
    my $password = $session->{args}->{Password} ||
        $Apache::Session::Store::Oracle::Password;
        
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
                SELECT a_session FROM $self->{'table_name'} WHERE id = ? FOR UPDATE});
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

Apache::Session::Store::Oracle - Store persistent data in a Oracle database

=head1 SYNOPSIS

 use Apache::Session::Store::Oracle;

 my $store = new Apache::Session::Store::Oracle;

 $store->insert($ref);
 $store->update($ref);
 $store->materialize($ref);
 $store->remove($ref);

=head1 DESCRIPTION

Apache::Session::Store::Oracle fulfills the storage interface of
Apache::Session. Session data is stored in a Oracle database.

=head1 SCHEMA

To use this module, you will need at least these columns in a table 
called 'sessions':

 id varchar2(32)     # or however long your session IDs are.
 a_session long

To create this schema, you can execute this command using the sqlplus program:

 CREATE TABLE sessions (
    id varchar2(32) not null primary key,
    a_session long
 );

If you use some other command, ensure that there is a unique index on the
table's id column.

=head1 CONFIGURATION

The module must know what datasource, username, and password to use when
connecting to the database.  These values can be set using the options hash
(see Apache::Session documentation).  The options are DataSource, UserName,
and Password.

Example:

 tie %hash, 'Apache::Session::Oracle', $id, {
     DataSource => 'dbi:Oracle:database',
     UserName   => 'database_user',
     Password   => 'K00l'
 };

Instead, you may pass in an already-opened DBI handle to your database.

 tie %hash, 'Apache::Session::Oracle', $id, {
     Handle => $dbh
 };

The last option is LongReadLen, which specifies the maximum size of the session
object.  If not supplied, the default maximum size is 8 KB.

=head1 AUTHOR

This modules was written by Jeffrey William Baker <jwbaker@acm.org>

A fix for the commit policy was contributed by Michael Schout <mschout@gkg.net>

=head1 SEE ALSO

L<Apache::Session>, L<Apache::Session::Store::DBI>
