package DJabberd::Delivery::OfflineStorage::SQLite;
use strict;
use base 'DJabberd::Delivery::OfflineStorage';
use warnings;
use DBI;

use vars qw($VERSION);
$VERSION = '0.04';

our $logger = DJabberd::Log->get_logger();

sub set_config_database {
    my ($self, $dbfile) = @_;
    $self->{dbfile} = $dbfile;
}

sub blocking { 1 };

sub finalize {
    my $self = shift;

    $logger->error_die("No 'Database' configured'") unless $self->{dbfile};

    my $dbh = DBI->connect_cached("dbi:SQLite:dbname=$self->{dbfile}","","",
                                  { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
    $self->{dbh} = $dbh;
    $self->check_install_schema;
    $logger->info("Loaded SQLite OfflineStorage using file '$self->{dbfile}'");

    $self->SUPER::finalize;
}


sub load_offline_messages {
    my ($self, $user) = @_;

    # collect packets for user
    my @packets = ();
    eval {
      my $sth = $self->{dbh}->prepare("SELECT id, jid, timestamp, packet FROM offline WHERE jid=? ORDER BY id");
      $sth->execute($user);
      while (my $packet = $sth->fetchrow_hashref()){
        push(@packets, $packet);
      }
    };
    if ($@) {
      $logger->warn("SELECT against user '$user' on dbfile '$self->{dbfile}' failed with: $@");
    }
    return \@packets;
}


sub delete_offline_message {
    my ($self, $id) = @_;

    # delete packet by id
    eval {
      $self->{dbh}->do("DELETE FROM offline WHERE id=?", undef, $id);
    };
    if ($@) {
      $logger->warn("DELETE for '$id' on dbfile '$self->{dbfile}' failed with: $@");
    }
}


sub store_offline_message {
    my ($self, $user, $packet) = @_;

    eval {
      $self->{dbh}->do("INSERT INTO offline (jid, timestamp, packet) VALUES (?,datetime('now'),?)",
                       undef, $user, $packet);
    };
    if ($@) {
      $logger->warn("INSERT for user '$user' on dbfile '$self->{dbfile}' failed with: $@");
    }
}

sub check_install_schema {
    my $self = shift;
    my $dbh = $self->{dbh};

    eval {
        $dbh->do(qq{
            CREATE TABLE offline (
                                 id        INTEGER PRIMARY KEY AUTOINCREMENT,
                                 jid       VARCHAR(255) NOT NULL,
                                 timestamp VARCHAR(255) NOT NULL,
                                 packet    BLOB,
                                 UNIQUE (jid, id)
                                 )})
        };
    if ($@ && $@ !~ /table \w+ already exists/) {
        $logger->logdie("SQL error $@");
    }

}


1;
