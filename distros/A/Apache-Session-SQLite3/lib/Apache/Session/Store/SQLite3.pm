package Apache::Session::Store::SQLite3;
$Apache::Session::Store::SQLite3::VERSION = '0.03';

use strict;
use base 'Apache::Session::Store::DBI';
use vars qw($TableName $DataSource $UserName $Password);

use DBI qw(:sql_types);
use Apache::Session::Store::DBI;

sub connection {
    my $self = shift;
    my $session = shift;

    $self->_connection($session) unless defined $self->{dbh};

    my $tables = $self->{dbh}->selectall_arrayref(qq[
        SELECT name
          FROM sqlite_master
         WHERE type = 'table'
           AND name = ?
    ], {}, $self->{table_name});

    $self->{dbh}->do(qq[
        CREATE TABLE $self->{table_name} (
            id char(32) NOT NULL,
            a_session LONGBLOB,
            LastUpdated TIMESTAMP,
            PRIMARY KEY (id)
        );
    ]) if !@$tables;
}

sub _connection {
    my $self = shift;
    my $session = shift;

    $self->{'table_name'} = $session->{args}->{TableName}
                            || $TableName
                            || $Apache::Session::Store::DBI::TableName;

    if (exists $session->{args}->{Handle}) {
        $self->{dbh} = $session->{args}->{Handle};
        return;
    }

    my $datasource = $session->{args}->{DataSource} || $DataSource;
    my $username = $session->{args}->{UserName} || $UserName;
    my $password = $session->{args}->{Password} || $Password;
        
    $self->{dbh} = DBI->connect(
        $datasource,
        $username,
        $password,
        { RaiseError => 1, AutoCommit => 1 }
    ) or die $DBI::errstr;
    
    $self->{disconnect} = 1;    
}

sub insert {
    my $self    = shift;
    my $session = shift;
 
    $self->connection($session);

    local $self->{dbh}->{RaiseError} = 1;

    if (!defined $self->{insert_sth}) {
        $self->{insert_sth} = $self->{dbh}->prepare_cached(qq[
             INSERT INTO $self->{'table_name'} (id, a_session, LastUpdated)
                  VALUES (?, ?, ?)
        ]);
    }

    $self->{insert_sth}->bind_param(1, $session->{data}->{_session_id}, SQL_CHAR);
    $self->{insert_sth}->bind_param(2, $session->{serialized}, SQL_BLOB);
    $self->{insert_sth}->bind_param(3, time, SQL_INTEGER);

    $self->{insert_sth}->execute;
    $self->{insert_sth}->finish;
}

sub update {
    my $self    = shift;
    my $session = shift;
 
    $self->connection($session);

    local $self->{dbh}->{RaiseError} = 1;

    if (!defined $self->{update_sth}) {
        $self->{update_sth} = $self->{dbh}->prepare_cached(qq[
             UPDATE $self->{'table_name'}
                SET a_session = ?, LastUpdated = ?
              WHERE id = ?
        ]);
    }

    $self->{update_sth}->bind_param(1, $session->{serialized}, SQL_BLOB);
    $self->{update_sth}->bind_param(2, time, SQL_INTEGER);
    $self->{update_sth}->bind_param(3, $session->{data}->{_session_id}, SQL_CHAR);

    foreach my $count (1..600) {
        local $@;
	eval { $self->{update_sth}->execute; 1 } and last;
	sleep 1;
    }
    $self->{update_sth}->finish;
}

1;
