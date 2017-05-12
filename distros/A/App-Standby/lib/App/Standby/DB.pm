package App::Standby::DB;
$App::Standby::DB::VERSION = '0.04';
BEGIN {
  $App::Standby::DB::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Database abstraction/helper for App::Standby

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;
use DBI;

# extends ...
# has ...
has 'dbh' => (
    'is'    => 'rw',
    'isa'   => 'DBI::db',
    'lazy'  => 1,
    'builder' => '_init_dbh',
);
# with ...
with qw(Config::Yak::RequiredConfig Log::Tree::RequiredLogger);
# initializers ...
sub _init_dbh {
    my $self = shift;

    my $db_file = $self->config()->get('App::Standby::DBFile', { Default => '/var/lib/standby-mgm/db.sqlite3'});

    my $dsn = 'DBI:SQLite:dbname='.$db_file;

    # see http://search.cpan.org/~adamk/DBD-SQLite-1.35/lib/DBD/SQLite.pm#Transaction_and_Database_Locking
    my $dbh = DBI->connect($dsn, '', '', { sqlite_use_immediate_transaction => 1, });

    if($dbh) {
        $self->_check_tables($dbh);
    }

    return $dbh;
}


sub DEMOLISH {
    my $self = shift;

    $self->dbh()->disconnect();

    return;
}

# your code here ...
sub prepare {
    my $self = shift;
    my $sqlstr = shift;

    return $self->dbh()->prepare($sqlstr);
}


sub prepexec {
    my ( $self, $sqlstr, @params ) = @_;

    my $sth = $self->dbh()->prepare($sqlstr);

    if(!$sth) {
        $self->logger()->log( message => 'Failed to prepare statement from SQL: '.$sqlstr.' w/ error: '.$self->dbh()->errstr, level => 'warning', );
        return;
    }
    if($sth->execute(@params)) {
        return $sth;
    } else {
        $self->logger()->log( message => 'Failed to execute statement w/ error: '.$sth->errstr, level => 'warning', );
        return;
    }
}


sub do {
    my $self = shift;

    return $self->dbh()->do(@_);
}


sub last_insert_id {
    my $self = shift;

    return $self->dbh()->last_insert_id(@_);
}


sub errstr {
    my $self = shift;
    return $self->dbh()->errstr();
}

sub _check_tables {
    my $self = shift;
    my $dbh = shift;

    # TODO LOW handle corrupted DB somehow
    # see http://www.sqlite.org/faq.html#q21 for possible approaches

    # TODO LOW add log table to record changes for some time
    # see http://www.sqlite.org/pragma.html#pragma_auto_vacuum for keeping the
    # disk usage low

    my $sql_meta = <<EOS;
CREATE TABLE IF NOT EXISTS meta (
        key TEXT,
        value TEXT,
        CONSTRAINT ukey UNIQUE (key) ON CONFLICT ABORT
);
EOS
    if($dbh->do($sql_meta)) {
        #$self->logger()->log( message => 'Table meta OK', level => 'debug', );
    } else {
        $self->logger()->log( message => 'Failed to create table meta: '.$dbh->errstr, level => 'error', );
    }

    my $sql_config = <<EOS;
CREATE TABLE IF NOT EXISTS config (
        id INTEGER PRIMARY KEY ASC,
        key TEXT,
        value TEXT,
        group_id INTEGER,
        CONSTRAINT fk_gid FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE
);
EOS
    if($dbh->do($sql_config)) {
        #$self->logger()->log( message => 'Table config OK', level => 'debug', );
    } else {
        $self->logger()->log( message => 'Failed to create table config: '.$dbh->errstr, level => 'error', );
    }

    my $sql_config_contacts = <<EOS;
CREATE TABLE IF NOT EXISTS config_contacts (
        id INTEGER PRIMARY KEY ASC,
        key TEXT,
        value TEXT,
        contact_id INTEGER,
        CONSTRAINT fk_cid FOREIGN KEY (contact_id) REFERENCES contacts (id) ON DELETE CASCADE
);
EOS
    if($dbh->do($sql_config_contacts)) {
        #$self->logger()->log( message => 'Table config OK', level => 'debug', );
    } else {
        $self->logger()->log( message => 'Failed to create table config_contacts: '.$dbh->errstr, level => 'error', );
    }

    # check that all required tables exist and create them if they don't
    my $sql_groups = <<EOS;
CREATE TABLE IF NOT EXISTS groups (
        id INTEGER PRIMARY KEY ASC,
        name TEXT,
        key TEXT
);
EOS

    if($dbh->do($sql_groups)) {
        #$self->logger()->log( message => 'Table groups OK', level => 'debug', );
    } else {
        $self->logger()->log( message => 'Failed to create table groups: '.$dbh->errstr, level => 'error', );
    }

    my $sql_group_services = <<EOS;
CREATE TABLE IF NOT EXISTS group_services (
        id INTEGER PRIMARY KEY ASC,
        group_id INTEGER,
        name TEXT,
        desc TEXT,
        class TEXT,
        CONSTRAINT fk_gid FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE,
        CONSTRAINT uq_name UNIQUE (group_id,name)
);
EOS

    if($dbh->do($sql_group_services)) {
        #$self->logger()->log( message => 'Table groups OK', level => 'debug', );
    } else {
        $self->logger()->log( message => 'Failed to create table group_services: '.$dbh->errstr, level => 'error', );
    }

    my $sql_ctcs = <<EOS;
CREATE TABLE IF NOT EXISTS contacts (
        id INTEGER PRIMARY KEY ASC,
        name TEXT,
        cellphone TEXT,
        group_id INTEGER,
        is_enabled INTEGER,
        ordinal INTEGER,
        CONSTRAINT fk_gid FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE
);
EOS

    if($dbh->do($sql_ctcs)) {
        #$self->logger()->log( message => 'Table contacts OK', level => 'debug', );
    } else {
        $self->logger()->log( message => 'Failed to create table contacts: '.$dbh->errstr, level => 'error', );
    }

    my $sql_log = <<EOS;
CREATE TABLE IF NOT EXISTS log (
        id INTEGER PRIMARY KEY ASC,
        group_id INTEGER,
        remote_addr INTEGER,
        msg TEXT,
);
EOS

    #if($dbh->do($sql_log)) {
    #    #$self->logger()->log( message => 'Table log OK', level => 'debug', );
    #} else {
    #    $self->logger()->log( message => 'Failed to create table log: '.$dbh->errstr, level => 'error', );
    #}

    my $sql_sstats = <<EOS;
CREATE TABLE IF NOT EXISTS shift_stats (
        id INTEGER PRIMARY KEY ASC,
        contact_id INTEGER,
        num_shifts INTEGER,
        CONSTRAINT fk_cid FOREIGN KEY (contact_id) REFERENCES contacts (id) ON DELETE CASCADE
);
EOS

    #if($dbh->do($sql_sstats)) {
    #    #$self->logger()->log( message => 'Table shift_stats OK', level => 'debug', );
    #} else {
    #    $self->logger()->log( message => 'Failed to create table shift_stats: '.$dbh->errstr, level => 'error', );
    #}

    # SQLite honors FK constraints only if the are explicitly turned on ...
    # http://www.sqlite.org/foreignkeys.html#fk_enable
    $dbh->do('PRAGMA foreign_keys = ON;');

    # Speed up a bit, if we encounter a crash we have more to worry about than
    # just a messed up spooler queue ...
    # http://www.sqlite.org/pragma.html#pragma_synchronous
    $dbh->do('PRAGMA synchronous = OFF;');

    $self->_check_db_version($dbh);

    return 1;
}

sub _check_db_version {
    my $self = shift;
    my $dbh = shift;

    $dbh->do('BEGIN TRANSACTION');

    my $db_version = 0; # set default
    my $sql = 'SELECT value FROM meta WHERE `key` = ?';
    my $sth = $dbh->prepare($sql);
    if($sth) {
        if($sth->execute('version')) {
            $db_version = $sth->fetchrow_array();
        } else {
            $self->logger()->log( message => 'Failed to execute statement w/ error: '.$sth->errstr, level => 'warning', );
        }
        $sth->finish();
    } else {
        $self->logger()->log( message => 'Failed to prepare statement from SQL: '.$sql.' w/ error: '.$dbh->errstr, level => 'warning', );
    }

    # place any version independent statements here

    # place any version dependent statements inside
    if(defined($db_version)) {
        if($db_version < 2) {
            # do upgrades to version 2 here
            # remove column class from table groups
            my $sql = <<EOS;
BEGIN TRANSACTION;
CREATE TEMPORARY TABLE groups_backup(id,name);
DROP TABLE groups;
CREATE TABLE IF NOT EXISTS groups (
        id INTEGER PRIMARY KEY ASC,
        name TEXT
);
INSERT INTO groups SELECT id,name FROM groups_backup;
DROP TABLE groups_backup;
COMMIT;
EOS
            # TODO HIGH do multi-statements work es expected?
            $dbh->do($sql);
        }
        if($db_version < 3) {
            my $sql = 'ALTER TABLE groups ADD COLOUMN key TEXT';
            $dbh->do($sql);
        }
        if($db_version < 4) {
            my $sql = 'DROP TABLE notify_order';
            $dbh->do($sql);
        }
        if($db_version < 5) {
            # remove column class from table contacts
            my $sql = <<EOS;
BEGIN TRANSACTION;
CREATE TEMPORARY TABLE contacts_backup(id,name,cellphone,group_id,is_enabled,ordinal);
DROP TABLE contacts;
CREATE TABLE IF NOT EXISTS contacts (
        id INTEGER PRIMARY KEY ASC,
        name TEXT,
        cellphone TEXT,
        group_id INTEGER,
        is_enabled INTEGER,
        ordinal INTEGER,
        CONSTRAINT fk_gid FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE
);
INSERT INTO contacts SELECT id,name,cellphone,group_id,is_enabled,ordinal FROM contacts_backup;
DROP TABLE contacts_backup;
COMMIT;
EOS
            # TODO HIGH do multi-statements work es expected?
            $dbh->do($sql);
        }
    }

    # finally we set the current version which we've reached by upgrading (or not)
    $sql = "INSERT OR REPLACE INTO meta ('key','value') VALUES('version',5);";
    $dbh->do($sql);

    $dbh->do('COMMIT');
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

App::Standby::DB - Database abstraction/helper for App::Standby

=head1 METHODS

=head2 DEMOLISH

Disconnect from the DB.

=head2 prepare

Call prepare on the internal DBI object. Will return an DBI statement.

=head2 prepexec

Prepare an SQL statement and execute it right away. Return
the statement object.

=head2 do

See DBI::do

=head2 last_insert_id

See DBI::last_insert_id

=head2 errstr

See DBI::errstr

=head1 NAME

App::Standby::DB - Database abstraction/helper for App::Standby

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
