package App::MonM::Notifier::Store; # $Id: Store.pm 81 2022-09-16 10:21:57Z abalama $
use strict;
use utf8;

=encoding utf8

=head1 NAME

App::MonM::Notifier::Store - monotifier store class

=head1 VERSION

Version 1.02

=head1 SYNOPSIS

    use App::MonM::Notifier::Store;

    my $store = App::MonM::Notifier::Store->new(
        dsn => "DBI:mysql:database=monotifier;host=mysql.example.com",
        user => "username",
        password => "password",
        set => [
            "RaiseError        0",
            "PrintError        0",
            "mysql_enable_utf8 1",
        ],
        expires => 3600*24*7,
        maxtime => 300,
    );

    die($store->error) if $store->error;

=head1 DESCRIPTION

DBI interface for monotifier store. This module provides store methods

=head2 new

    my $store = App::MonM::Notifier::Store->new(
        dsn => "DBI:mysql:database=monotifier;host=mysql.example.com",
        user => "username",
        password => "password",
        set => [
            "RaiseError        0",
            "PrintError        0",
            "mysql_enable_utf8 1",
        ],
        expires => 3600*24*7,
        maxtime => 300,
    );

Creates DBI object

=over 8

=item B<expires>

    Time in seconds of life of database record

=item B<maxtime>

    Max time in seconds to sending one message

=back

=head2 cleanup

    my $st = $store->cleanup;

Removes permanently queue entities based on how old they are

=head2 dequeue

    my $st = $store->dequeue(
        id => 1,
    );

Dequeues the element by setting success status (STATUS_SENT)

=head2 delById

    $store->delById($id) or die($store->error);

Delete record by id

=head2 dsn

    my $dsn = $store->dsn;

Returns DSN string of current database connection

=head2 enqueue

    $store->enqueue(
        to      => $user,
        channel => $ch_name,
        subject => $subject,
        message => $message,
        attributes => $ch, # Channel attributes
    ) or die($store->error);

Adds a new element at the end of the current queue
and returns queue element ID

=head2 error

    my $error = $store->error;

Returns error message

    my $error = $store->error( "Error message" );

Sets error message if argument is provided.

=head2 getById

    my %data = $store->getById($id);

Returns data from database by id

=head2 getAll

    my @table = $store->getAll();
    my @table_100 = $store->getAll(100);

Returns data from database with limit supporting

=head2 is_sqlite

    print $store->is_sqlite ? "Is SQLite" : "Is not SQLite"

Returns true if type of current database is SQLite

=head2 ping

    $store->ping ? 'OK' : 'Database session is expired';

Checks the connection to database

=head2 requeue

    my $st = $store->requeue(
        id => 1,
        code => 2,
        error => "My Error",
    );

Requeue entities that have been retrieved for processing early; sets status to STATUS_FAIL

=head2 retrieve

    my $entity = $store->retrieve(STATUS_FAIL);

Retrieves the next entity from the queue and returns it as hashref
or undef if no entity

=head2 serializer

    my $serializer = $store->serializer;

Returns serializer object

=head2 purge

    $store->purge or die($store->error);

Delete all records

=head1 DDL

    CREATE TABLE IF NOT EXISTS monotifier (
        `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
        `to` CHAR(255), -- Recipient name
        `channel` CHAR(255), -- Recipient channel
        `subject` TEXT, -- Message subject
        `message` TEXT, -- Message content (BASE64)
        `attributes` TEXT, -- Message attributes (JSON)
        `published` BIGINT(20), -- The publication time (unixtime)
        `scheduled` BIGINT(20), -- The scheduled time (unixtime)
        `expired` BIGINT(20), -- The expiration time (unixtime)
        `sent` BIGINT(20), -- The send time
        `attempt` INTEGER DEFAULT 0, -- Count of failed attempts
        `status` CHAR(32), -- Status of transaction
        `errcode` INT(11), -- Error code
        `errmsg` TEXT -- Error message
    )

=head1 ERRORCODES

    0    -- No errors found
    1    -- Error of the notifier level (notify method)
    2    -- Error of the notifier level (remind method)
    255  -- Error of the cleanup level

=head1 SEE ALSO

L<CTK::DBI>, L<App::MonM>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '1.02';

use File::Spec;
use MIME::Base64 qw/encode_base64 decode_base64/;

use CTK::DBI;
use CTK::Util qw/ read_attributes touch /;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use CTK::Serializer;

use App::MonM::Const;
use App::MonM::Util qw/ set2attr /;

use constant {
    EXPIRES     => 30*24*60*60, # 30 days max (how time to hold of messages)
    MAXTIME     => 300, # 5 min
    JSON_ATTRS  => [
            { # For serialize
                utf8 => 0,
                pretty => 1,
                allow_nonref => 1,
                allow_blessed => 1,
            },
            { # For deserialize
                utf8 => 0,
                allow_nonref => 1,
                allow_blessed => 1,
            },
        ],

    # Database
    DB_FILENAME_NASK    => 'monotifier-%s.db', # username
    DEFAULT_DSN_MASK    => 'dbi:SQLite:dbname=%s',
    DEFAULT_DBI_ATTR    => {
            dsn         => '', # See DEFAULT_DSN_MASK
            user        => '',
            password    => '',
            set         => [
                    'RaiseError 0',
                    'PrintError 0',
                    'sqlite_unicode 1',
                ],
        },

    # Statuses
    STATUS_NEW      => 'NEW',
    STATUS_BUSY     => 'BUSY',
    STATUS_FAIL     => 'FAIL', # See Attempt
    STATUS_SENT     => 'SENT',
};

use constant MONOTIFIER_DDL => <<'DDL';
CREATE TABLE IF NOT EXISTS monotifier (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
    `to` CHAR(255), -- Recipient name
    `channel` CHAR(255), -- Recipient channel
    `subject` TEXT, -- Message subject
    `message` TEXT, -- Message content (BASE64)
    `attributes` TEXT, -- Message attributes (JSON)
    `published` BIGINT(20), -- The publication time (unixtime)
    `scheduled` BIGINT(20), -- The scheduled time (unixtime)
    `expired` BIGINT(20), -- The expiration time (unixtime)
    `sent` BIGINT(20), -- The send time
    `attempt` INTEGER DEFAULT 0, -- Count of failed attempts
    `status` CHAR(32), -- Status of transaction
    `errcode` INT(11), -- Error code
    `errmsg` TEXT -- Error message
)
DDL

use constant MONOTIFIER_ADD => <<'DML';
INSERT INTO monotifier
    (`to`,`channel`,`subject`,`message`,`attributes`,`published`,`scheduled`,`expired`,`sent`,`attempt`,`status`,`errcode`,`errmsg`)
VALUES
    (?,?,?,?,?,?,?,?,?,?,?,?,?)
DML

use constant MONOTIFIER_GET_NEXT => <<'DML';
SELECT `id`,`to`,`channel`,`subject`,`message`,`attributes`,`published`,`scheduled`,`expired`,`sent`,`attempt`,`status`,`errcode`,`errmsg`
FROM `monotifier`
WHERE `scheduled` <= ? AND `status` = ?
LIMIT 1
DML

use constant MONOTIFIER_UPDATE_STATUS => <<'DML';
UPDATE `monotifier`
SET `status` = ?, `scheduled` = ?, `sent` = ?, `attempt` = ?, `errcode` = ?, `errmsg` = ?
WHERE `id` = ?
DML

use constant MONOTIFIER_UPDATE_ERROR => <<'DML';
UPDATE `monotifier`
SET `status` = ?, `errcode` = ?, `errmsg` = ?
WHERE `id` = ?
DML

use constant MONOTIFIER_CLEANUP => <<'DML';
DELETE FROM `monotifier`
WHERE `expired` <= ?
DML

use constant MONOTIFIER_FLUSH => <<'DML';
UPDATE `monotifier`
SET `status` = ?, `errcode` = ?, `errmsg` = ?
WHERE (`status` = ? OR `status` = ?) AND `scheduled` < ?
DML

use constant MONOTIFIER_PURGE => <<'DML';
DELETE FROM monotifier
DML

use constant MONOTIFIER_GET_ALL => <<'DML';
SELECT `id`,`to`,`channel`,`subject`,`message`,`attributes`,`published`,`scheduled`,`expired`,`sent`,`attempt`,`status`,`errcode`,`errmsg`
FROM monotifier
ORDER BY `id` DESC
DML

use constant MONOTIFIER_GET_BY_ID => <<'DML';
SELECT `id`,`to`,`channel`,`subject`,`message`,`attributes`,`published`,`scheduled`,`expired`,`sent`,`attempt`,`status`,`errcode`,`errmsg`
FROM monotifier
WHERE `id` = ?
DML

use constant MONOTIFIER_DEL_BY_ID => <<'DML';
DELETE FROM monotifier WHERE `id` = ?
DML

sub new {
    my $class = shift;
    my %args = @_;
    unless ($args{dsn}) {
        my $dda = DEFAULT_DBI_ATTR;
        foreach (%$dda) {
            $args{$_} //= $dda->{$_}
        }
    }
    my $username = getlogin() || (getpwuid($>))[0] || $ENV{LOGNAME} || $ENV{USER} || "anonymous";
    my $filename = sprintf(DB_FILENAME_NASK, $username);
    my $file = $args{file} || File::Spec->catfile(File::Spec->tmpdir(), $filename);
    my $dsn = $args{dsn} || sprintf(DEFAULT_DSN_MASK, $file);

    # DB
    my $db = CTK::DBI->new(
        -dsn    => $dsn,
        -debug  => 0,
        -username => $args{'user'},
        -password => $args{'password'},
        -attr     => set2attr($args{'set'}),
        $args{timeout} ? (
            -timeout_connect => $args{timeout},
            -timeout_request => $args{timeout},
        ) : (),
    );
    my $dbh = $db->connect if $db;

    # SQLite
    my $fnew = 0;
    my $issqlite = 0;
    if ($dbh && $dsn =~ /SQLite/i) {
        $file = $dbh->sqlite_db_filename();
        unless ($file && (-e $file) && !(-z $file)) {
            touch($file);
            chmod(0666, $file);
            $fnew = 1;
        }
        $issqlite = 1;
    }

    # Errors
    my $error = "";
    if (!$db) {
        $error = sprintf("Can't init database \"%s\"", $dsn);
    } elsif (!$dbh) {
        $error = sprintf("Can't connect to database \"%s\": %s", $dsn, $DBI::errstr || "unknown error");
    } elsif ($fnew) {
        $db->execute(MONOTIFIER_DDL);
        $error = $dbh->errstr() if $dbh->err;
    }
    unless ($error) {
        $error = sprintf("Can't init database \"%s\". Ping failed: %s",
            $dsn, $dbh->errstr() || "unknown error") unless $dbh->ping;
    }

    my $self = bless {
            file    => $file,
            issqlite=> $issqlite,
            dsn     => $dsn,
            error   => $error,
            dbi     => $db,
            expires => $args{expires} || EXPIRES,
            maxtime => $args{maxtime} || MAXTIME,
            serializer => CTK::Serializer->new('json', attrs => { json => JSON_ATTRS }),
        }, $class;

    return $self;
}
sub error {
    my $self = shift;
    my $err = shift;
    return $self->{error} unless defined $err;
    $self->{error} = $err;
    return $self->{error};
}
sub ping {
    my $self = shift;
    return 0 unless $self->{dsn};
    my $dbi = $self->{dbi};
    return 0 unless $dbi;
    my $dbh = $dbi->{dbh};
    return 0 unless $dbh;
    return 1 unless $dbh->can('ping');
    return $dbh->ping();
}
sub dsn {
    my $self = shift;
    return $self->{dsn};
}
sub serializer {
    my $self = shift;
    return $self->{serializer};
}
sub is_sqlite {
    my $self = shift;
    return $self->{issqlite} ? 1 : 0;
}

# CRUD Methods

sub getAll {
    my $self = shift;
    my $limit = shift || 0;
    return () unless $self->ping;
    $self->error("");
    my $dbi = $self->{dbi};

    my @tbl = $dbi->table(sprintf("%s%s", MONOTIFIER_GET_ALL,  $limit ? " LIMIT $limit" : "" ));
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't get records: %s", uv2null($dbi->connect->errstr)));
        return ();
    }
    return @tbl;
}
sub getById {
    my $self = shift;
    my $id = shift || 0;
    my $dbi = $self->{dbi};
    $self->error("");

    my %rec = $dbi->recordh(MONOTIFIER_GET_BY_ID, $id);
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't get record: %s", uv2null($dbi->connect->errstr)));
        return ();
    }

    if (defined($rec{message}) && length($rec{message})) {
        $rec{message} = decode_base64($rec{message});
    }
    if (defined($rec{attributes}) && length($rec{attributes})) {
        $rec{attributes} = $self->serializer->deserialize($rec{attributes});
        unless ($self->serializer->status) {
            $self->error(sprintf("Can't deserialize channel attributes: %s", uv2null($self->serializer->error)));
            return ();
        }
    }

    return %rec;
}
sub delById {
    my $self = shift;
    my $id = shift || 0;
    my $dbi = $self->{dbi};
    $self->error("");

    $dbi->execute(MONOTIFIER_DEL_BY_ID, $id);
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't delete record: %s", uv2null($dbi->connect->errstr)));
        return 0;
    }
    return 1;
}

# Queue methods

sub enqueue { # Set STATUS_NEW
    my $self = shift;
    my ($to, $ch_name, $ch_attr, $subject, $message) =
        read_attributes([
            [qw/TO USER USERNAME RECIPIENT/],
            [qw/NAME CHANNEL CH_NAME/],
            [qw/ATTR ATTRS ATTRIBUTES CH_ATTR CH_ATTRS/],
            [qw/SUBJECT SUBJ SBJ/],
            [qw/MESSAGE MSG/],
        ], @_);
    return 0 unless $self->ping;
    $self->error("");
    my $dbi = $self->{dbi};

    # Add new record
    my $now = time();
    my $json = $self->serializer->serialize($ch_attr);
    unless ($self->serializer->status) {
        $self->error(sprintf("Can't serialize channel attributes: %s", uv2null($self->serializer->error)));
        return 0;
    }

    # Add new record
    $dbi->execute(MONOTIFIER_ADD,
        $to, $ch_name, $subject, encode_base64($message), $json,
        $now, # published
        $now, # scheduled
        ($now + $self->{expires}), # expired
        undef, # sent
        0, # attempt
        STATUS_NEW, # status
        undef, # errcode
        undef, # errmsg
    );
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't insert new record: %s", uv2null($dbi->connect->errstr)));
        return 0;
    }

    # Get ID
    my $id = $self->{issqlite}
        ? $dbi->connect->sqlite_last_insert_rowid()
        : $dbi->connect->last_insert_id();

    return $id || 0;
}
sub retrieve { # Set STATUS_BUSY
    my $self = shift;
    my ($status) =
        read_attributes([
            [qw/STATUS REQUIRE REQ/],
        ], @_);
    return unless $self->ping;
    $self->error("");
    my $dbi = $self->{dbi};

    # status == ? || STATUS_FAIL; scheduled <= now();
    my $now = time();
    my %rec = $dbi->recordh(MONOTIFIER_GET_NEXT, $now, $status || STATUS_FAIL);
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't get record: %s", uv2null($dbi->connect->errstr)));
        return;
    }
    return unless %rec;

    # Set status to STATUS_BUSY
    my $attempt = $rec{attempt} || 0;
    $dbi->execute(MONOTIFIER_UPDATE_STATUS,
        STATUS_BUSY, # status
        $now + _sheduled_calc($attempt), # scheduled
        undef, # sent
        ++$attempt, # attempt (new)
        undef, # errcode
        undef, # errmsg
        $rec{id} || 0
    );
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't change status: %s", uv2null($dbi->connect->errstr)));
        return;
    }

    if (defined($rec{message}) && length($rec{message})) {
        $rec{message} = decode_base64($rec{message});
    }
    if (defined($rec{attributes}) && length($rec{attributes})) {
        $rec{attributes} = $self->serializer->deserialize($rec{attributes});
        unless ($self->serializer->status) {
            $self->error(sprintf("Can't deserialize channel attributes: %s", uv2null($self->serializer->error)));
            return;
        }
    }

    return {%rec};
}
sub requeue { # Set STATUS_FAIL
    my $self = shift;
    my ($id, $code, $error) =
        read_attributes([
            [qw/ID/],
            [qw/CODE ERRCODEE ERR_CODE/],
            [qw/ERROR ERRMESSAGE ERRMSG ERR_MESSAGE ERR_MSG/],
        ], @_);
    return 0 unless $self->ping;
    $self->error("");
    my $dbi = $self->{dbi};

    # Set status
    $dbi->execute(MONOTIFIER_UPDATE_ERROR,
        STATUS_FAIL, # status
        $code, # errcode
        $error, # errmsg
        $id || 0
    );
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't update record: %s", uv2null($dbi->connect->errstr)));
        return 0;
    }

    return 1;
}
sub dequeue { # Set STATUS_SENT
    my $self = shift;
    my ($id) =
        read_attributes([
            [qw/ID/],
        ], @_);
    return 0 unless $self->ping;
    $self->error("");
    my $dbi = $self->{dbi};

    # Set status to STATUS_SENT
    $dbi->execute(MONOTIFIER_UPDATE_STATUS,
        STATUS_SENT, # status
        undef, # scheduled
        time(), # sent
        0, # attempt
        undef, # errcode
        undef, # errmsg
        $id || 0
    );
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't change status: %s", uv2null($dbi->connect->errstr)));
        return;
    }

    return $id;
}
sub cleanup { # Delete too old records by expired field
    my $self = shift;
    return 0 unless $self->ping;
    $self->error("");
    my $dbi = $self->{dbi};

    # CleanUp (by expired)
    my $now = time();
    $dbi->execute(MONOTIFIER_CLEANUP, $now);
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't delete records (cleanup): %s", uv2null($dbi->connect->errstr)));
        return 0;
    }

    # CleanUp (by maxtime)
    my $maxtime = $self->{maxtime} || MAXTIME;
    $dbi->execute(MONOTIFIER_FLUSH,
        STATUS_FAIL, # status
        255, # errcode (Cleanup level)
        "Sending the message is taking too long!", # errmsg
        STATUS_BUSY, STATUS_NEW,
        $now - $maxtime,
    );
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't update records (cleanup): %s", uv2null($dbi->connect->errstr)));
        return 0;
    }

    return 1;
}
sub purge {
    my $self = shift;
    return 0 unless $self->ping;
    $self->error("");
    my $dbi = $self->{dbi};

    $dbi->execute(MONOTIFIER_PURGE);
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't purge table: %s", uv2null($dbi->connect->errstr)));
        return 0;
    }
    return 1;
}

sub _sheduled_calc {
    my $t = shift; # Attempt number
    if ($t >= 0 and $t < 5)         { return 60         } # 1 min per 5 min (5 times)
    elsif ($t >= 5 and $t < 7)      { return 60*5       } # 5 min per 15 min (2 times)
    elsif ($t >= 7 and $t < 10)     { return 60*15      } # 15 min per 1 hour (3 times)
    elsif ($t >= 10 and $t < 33)    { return 60*60      } # 1 hour per day (23 times)
    elsif ($t >= 33 and $t < 39)    { return 60*60*24   } # 1 day per week (6 times)
    elsif ($t >= 39 and $t < 42)    { return 60*60*24*7 } # 1 week per month (3 times)
    return 60*60*24*30; # every 1 month
}

1;

__END__
