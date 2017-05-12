
package DJabberd::Authen::SQLite;
use strict;
use base 'DJabberd::Authen';

use DJabberd::Log;
our $logger = DJabberd::Log->get_logger;
use DBI;

use vars qw($VERSION);
$VERSION = '0.01';

sub log {
    $logger;
}

=head1 NAME

DJabberd::Authen::SQLite - A SQLite authentication module for DJabberd

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    <VHost mydomain.com>

        [...]

        <Plugin DJabberd::Authen::SQLite>
            DBName               djabberd
            DBTable              user
            DBUsernameColumn     username
            DBPasswordColumn     password
            DBWhere              canjabber = 1
        </Plugin>
    </VHost>

DBName, DBTable, DBUsernameColumn and DBPasswordColumn are required.
Everything else is optional.
 

=head1 AUTHOR

Piers Harding, piers@cpan.org.


=cut


sub set_config_database {
    my ($self, $dbfile) = @_;
    $self->{dbfile} = $dbfile;
    $logger->info("Loaded SQLite Authen using file '$dbfile'");
}

sub check_install_schema {
    my $self = shift;
    my $dbh = $self->{sqlite_dbh};

    eval {
        $dbh->do(qq{
            CREATE TABLE $self->{sqlite_table} (
                                 $self->{sqlite_usernamecolumn}   VARCHAR(255),
                                 $self->{sqlite_passwordcolumn}   VARCHAR(255),
                                 PRIMARY KEY ($self->{sqlite_usernamecolumn})
                                 )});
    };
    if ($@ && $@ !~ /table \w+ already exists/) {
        $logger->logdie("SQL error $@");
        die "SQL error: $@\n";
    }

    $logger->info("Created SQLite users tables");

}

sub blocking { 1 };

sub set_config_dbtable {
    my ($self, $dbtable) = @_;
    $self->{'sqlite_table'} = $dbtable;
}

sub set_config_dbusernamecolumn {
    my ($self, $dbusernamecolumn) = @_;
    $self->{'sqlite_usernamecolumn'} = $dbusernamecolumn;
}

sub set_config_dbpasswordcolumn {
    my ($self, $dbpasswordcolumn) = @_;
    $self->{'sqlite_passwordcolumn'} = $dbpasswordcolumn;
}

sub set_config_dbwhere {
    my ($self, $dbwhere) = @_;
    $self->{'sqlite_where'} = $dbwhere;
}

sub finalize {
    my $self = shift;
    die "No 'Database' configured'" unless $self->{dbfile};
    my $dsn = "dbi:SQLite:dbname=$self->{'dbfile'}";
    my $dbh = DBI->connect($dsn, "", "", { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
    $self->{'sqlite_dbh'} = $dbh;
    $self->check_install_schema;
    return $self;
}

sub can_register_jids {
    1;
}

sub can_unregister_jids {
    1;
}

sub can_retrieve_cleartext {
    my $self = shift;
    return 1;
}

sub get_password {
    my ($self, $cb, %args) = @_;

    my $user = $args{'username'};
    my $dbh = $self->{'sqlite_dbh'};

    my $sql_username = "SELECT $self->{'sqlite_usernamecolumn'}, $self->{'sqlite_passwordcolumn'} FROM $self->{'sqlite_table'} WHERE $self->{'sqlite_usernamecolumn'} = ".$dbh->quote($user);
    my $sql_where = (defined $self->{'sqlite_where'} ? " AND $self->{'sqlite_where'}" : "");

    my ($username, $password) = $dbh->selectrow_array("$sql_username $sql_where");
    if (defined $username) {
        $logger->debug("Fetched password for '$username'");
        $cb->set($password);
        return;
    }
    $logger->info("Can't fetch password for '$username': user does not exist or did not satisfy WHERE clause");
    $cb->decline;
}

sub register_jid {
    my ($self, $cb, %args) = @_;
    my $username = $args{'username'};
    my $password = $args{'password'};
    my $dbh = $self->{'sqlite_dbh'};

    if (defined(($dbh->selectrow_array("SELECT * FROM $self->{'sqlite_table'} WHERE $self->{'sqlite_usernamecolumn'} = " . $dbh->quote($username)))[0])) { # if user exists
        $logger->info("Registration failed for user '$username': user exists");
        $cb->conflict;
        return 0;
    } else {
        eval {
            $dbh->do("INSERT INTO $self->{'sqlite_table'} ( $self->{'sqlite_usernamecolumn'}, $self->{'sqlite_passwordcolumn'} ) VALUES ( " . $dbh->quote($username) .  ", " . $dbh->quote($password) ." )");
        };
        if ($@) {
            $logger->info("Registration failed for user '$username': database query failed: $@");
            $cb->error;
            return 0;
        } else {
            $logger->debug("User '$username' registered successfully");
            $cb->saved;
            return 1;
        }
    }
}

sub unregister_jid {
    my ($self, $cb, %args) = @_;
    my $username = $args{'username'};
    my $dbh = $self->{'sqlite_dbh'};

    if (defined(($dbh->selectrow_array("SELECT * FROM $self->{'sqlite_table'} WHERE $self->{'sqlite_usernamecolumn'} = " . $dbh->quote($username)))[0])) { # if user exists
        eval {
            $dbh->do("DELETE FROM $self->{'sqlite_table'} WHERE $self->{'sqlite_usernamecolumn'} = " . $dbh->quote($username));
        };
        if ($@) {
            $logger->info("Cancellation of registration failed for user '$username': database query failed");
            $cb->error;
            return 0;
        } else {
            $logger->debug("User '$username' canceled registration successfully");
            $cb->deleted;
            return 1;
        }
    } else {
        $logger->info("Cancellation of registration failed for user '$username': user not found");
        $cb->notfound;
        return 0;
    }
}

sub check_cleartext {
    my ($self, $cb, %args) = @_;
    my $username = $args{username};
    my $password = $args{password};
    my $conn = $args{conn};
    unless ($username =~ /^\w+$/) {
        $cb->reject;
        return;
    }

    my $dbh = $self->{'sqlite_dbh'};
    my $sql_username = "SELECT $self->{'sqlite_usernamecolumn'} FROM $self->{'sqlite_table'} WHERE $self->{'sqlite_usernamecolumn'} = ".$dbh->quote($username);
    my $sql_password = " AND $self->{'sqlite_passwordcolumn'} = ". $dbh->quote($password);
    my $sql_where = (defined $self->{'sqlite_where'} ? " AND $self->{'sqlite_where'}" : "");

    if (defined(($dbh->selectrow_array("$sql_username $sql_password $sql_where"))[0])) {
        $cb->accept;
        $logger->debug("User '$username' authenticated successfully");
        return 1;
    } else {
        $cb->reject();
        if (defined(($dbh->selectrow_array("$sql_username $sql_where"))[0])) { # if user exists
            $logger->info("Auth failed for user '$username': password error");
            return 0;
        } else {
            $logger->info("Auth failed for user '$username': user does not exist or did not satisfy WHERE clause");
            return 1;
        }
    }
}

=head1 COPYRIGHT & LICENSE

Original work Copyright 2006 Alexander Karelas, Martin Atkins, Brad Fitzpatrick and Aleksandar Milanov. All rights reserved.
Copyright 2007 Piers Harding.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
