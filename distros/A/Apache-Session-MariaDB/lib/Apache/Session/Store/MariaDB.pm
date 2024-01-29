package Apache::Session::Store::MariaDB;

use strict;

use DBI;
use Apache::Session::Store::DBI;

use base 'Apache::Session::Store::DBI';

$Apache::Session::Store::MariaDB::DataSource = undef;
$Apache::Session::Store::MariaDB::UserName   = undef;
$Apache::Session::Store::MariaDB::Password   = undef;

sub connection {
    my $self    = shift;
    my $session = shift;

    return if ( defined $self->{dbh} );

    $self->{'table_name'} = $session->{args}->{TableName} || $Apache::Session::Store::DBI::TableName;

    if ( exists $session->{args}->{Handle} ) {
        $self->{dbh} = $session->{args}->{Handle};
        return;
    }

    my $datasource = $session->{args}->{DataSource}
        || $Apache::Session::Store::MariaDB::DataSource;
    my $username = $session->{args}->{UserName}
        || $Apache::Session::Store::MariaDB::UserName;
    my $password = $session->{args}->{Password}
        || $Apache::Session::Store::MariaDB::Password;

    $self->{dbh} = DBI->connect( $datasource, $username, $password, { RaiseError => 1, AutoCommit => 1 } )
        || die $DBI::errstr;


    #If we open the connection, we close the connection
    $self->{disconnect} = 1;
}

sub DESTROY {
    my $self = shift;

    if ( $self->{disconnect} ) {
        $self->{dbh}->disconnect;
    }
}

# DBD::MariaDB requires to explicitly indicate a_session is a binary field
sub insert {
    my $self    = shift;
    my $session = shift;

    $self->connection($session);

    local $self->{dbh}->{RaiseError} = 1;

    if ( !defined $self->{insert_sth} ) {
        $self->{insert_sth} = $self->{dbh}->prepare_cached(
            qq{
                INSERT INTO $self->{'table_name'} (id, a_session) VALUES (?,?)}
        );
    }

    $self->{insert_sth}->bind_param( 1, $session->{data}->{_session_id} );
    $self->{insert_sth}->bind_param( 2, $session->{serialized}, DBI::SQL_BLOB );

    $self->{insert_sth}->execute;

    $self->{insert_sth}->finish;
}


sub update {
    my $self    = shift;
    my $session = shift;

    $self->connection($session);

    local $self->{dbh}->{RaiseError} = 1;

    if ( !defined $self->{update_sth} ) {
        $self->{update_sth} = $self->{dbh}->prepare_cached(
            qq{
                UPDATE $self->{'table_name'} SET a_session = ? WHERE id = ?}
        );
    }

    $self->{update_sth}->bind_param( 1, $session->{serialized}, DBI::SQL_BLOB );
    $self->{update_sth}->bind_param( 2, $session->{data}->{_session_id} );

    $self->{update_sth}->execute;

    $self->{update_sth}->finish;
}

1;

=pod

=head1 NAME

Apache::Session::Store::MariaDB - Store persistent data in a MariaDB database

=head1 SYNOPSIS

 use Apache::Session::Store::MariaDB;

 my $store = new Apache::Session::Store::MariaDB;

 $store->insert($ref);
 $store->update($ref);
 $store->materialize($ref);
 $store->remove($ref);

=head1 DESCRIPTION

Apache::Session::Store::MariaDB fulfills the storage interface of          .
Apache::Session Session data is stored in a MariaDB database               .

=head1 SCHEMA

To use this module, you will need at least these columns in a table called
'sessions', or another table name if you provide the TableName argument:

 id char(32)     # or however long your session IDs are.
 a_session blob  # or longblob if you plan to use a big session (>64k after serialization)

To create this schema, you can execute this command using the MariaDB
program:

 CREATE TABLE sessions (
    id char(32) not null primary key,
    a_session blob
 );

If you use some other command, ensure that there is a unique index on the
table's id column.

=head1 CONFIGURATION

The module must know what datasource, username, and password to use when
connecting to the database. These values can be set using the options hash
(see Apache::Session documentation). The options are:

=over 4

=item DataSource

=item UserName

=item Password

=item TableName

=item Handle

=back

Example:

 tie %hash, 'Apache::Session::MariaDB', $id, {
     DataSource => 'dbi:MariaDB:database',
     UserName   => 'database_user',
     Password   => 'K00l',
     TableName  => 'sessions'
 };

Instead, you may pass in an already-opened DBI handle to your database.

 tie %hash, 'Apache::Session::MariaDB', $id, {
     Handle => $dbh
 };

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

Jeffrey William Baker E<lt>jwbaker@acm.orgE<gt>

=head1 SEE ALSO

L<Apache::Session>
