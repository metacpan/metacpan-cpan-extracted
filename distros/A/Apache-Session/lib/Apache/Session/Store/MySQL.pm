#############################################################################
#
# Apache::Session::Store::MySQL
# Implements session object storage via MySQL
# Copyright(c) 1998, 1999, 2000, 2004 Jeffrey William Baker (jwbaker@acm.org)
# Distribute under the Perl License
#
############################################################################

package Apache::Session::Store::MySQL;

use strict;

use DBI;
use Apache::Session::Store::DBI;

use vars qw(@ISA $VERSION);

@ISA = qw(Apache::Session::Store::DBI);
$VERSION = '1.04';

$Apache::Session::Store::MySQL::DataSource = undef;
$Apache::Session::Store::MySQL::UserName   = undef;
$Apache::Session::Store::MySQL::Password   = undef;

sub connection {
    my $self    = shift;
    my $session = shift;
    
    return if (defined $self->{dbh});

	$self->{'table_name'} = $session->{args}->{TableName} || $Apache::Session::Store::DBI::TableName;

    if (exists $session->{args}->{Handle}) {
        $self->{dbh} = $session->{args}->{Handle};
        return;
    }

    my $datasource = $session->{args}->{DataSource} || 
        $Apache::Session::Store::MySQL::DataSource;
    my $username = $session->{args}->{UserName} ||
        $Apache::Session::Store::MySQL::UserName;
    my $password = $session->{args}->{Password} ||
        $Apache::Session::Store::MySQL::Password;
        
    $self->{dbh} = DBI->connect(
        $datasource,
        $username,
        $password,
        { RaiseError => 1, AutoCommit => 1 }
    ) || die $DBI::errstr;

    
    #If we open the connection, we close the connection
    $self->{disconnect} = 1;    
}

sub DESTROY {
    my $self = shift;
    
    if ($self->{disconnect}) {
        $self->{dbh}->disconnect;
    }
}


1;

=pod

=head1 NAME

Apache::Session::Store::MySQL - Store persistent data in a MySQL database

=head1 SYNOPSIS

 use Apache::Session::Store::MySQL;

 my $store = new Apache::Session::Store::MySQL;

 $store->insert($ref);
 $store->update($ref);
 $store->materialize($ref);
 $store->remove($ref);

=head1 DESCRIPTION

Apache::Session::Store::MySQL fulfills the storage interface of Apache::Session.
Session data is stored in a MySQL database.

=head1 SCHEMA

To use this module, you will need at least these columns in a table 
called 'sessions', or another table name if you provide the TableName
argument:

 id char(32)     # or however long your session IDs are.
 a_session blob  # or varbinary if you plan to use a big session (>64k after serialization)

To create this schema, you can execute this command using the mysql program:

 CREATE TABLE sessions (
    id char(32) not null primary key,
    a_session blob
 );

If you use some other command, ensure that there is a unique index on the
table's id column.

=head1 CONFIGURATION

The module must know what datasource, username, and password to use when
connecting to the database.  These values can be set using the options hash
(see Apache::Session documentation).  The options are:

=over 4

=item DataSource

=item UserName

=item Password

=item TableName

=item Handle

=back

Example:

 tie %hash, 'Apache::Session::MySQL', $id, {
     DataSource => 'dbi:mysql:database',
     UserName   => 'database_user',
     Password   => 'K00l',
     TableName  => 'sessions'
 };

Instead, you may pass in an already-opened DBI handle to your database.

 tie %hash, 'Apache::Session::MySQL', $id, {
     Handle => $dbh
 };

=head1 AUTHOR

This modules was written by Jeffrey William Baker <jwbaker@acm.org>

=head1 SEE ALSO

L<Apache::Session>
