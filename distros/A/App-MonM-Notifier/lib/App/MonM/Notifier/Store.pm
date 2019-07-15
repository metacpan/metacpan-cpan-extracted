package App::MonM::Notifier::Store; # $Id: Store.pm 60 2019-07-14 09:57:26Z abalama $
use strict;
use utf8;

=encoding utf8

=head1 NAME

App::MonM::Notifier::Store - monotifier store class

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use App::MonM::Notifier::Store;

    my $store = new App::MonM::Notifier::Store(
        dsn => "DBI:mysql:database=monotifier;host=mysql.example.com",
        user => "username",
        password => "password",
        set => [
            "RaiseError        0",
            "PrintError        0",
            "mysql_enable_utf8 1",
        ],
    );

    die($store->error) unless $store->status;

=head1 DESCRIPTION

This module provides store methods.

    CREATE TABLE IF NOT EXISTS `monotifier` (
      `id` int(11) NOT NULL COMMENT 'ID',
      `to` char(255) DEFAULT NULL COMMENT 'Recipient name',
      `channel` char(255) DEFAULT NULL COMMENT 'Recipient channel',
      `subject` text COMMENT 'Message subject',
      `message` text COMMENT 'Message content',
      `pubdate` int(11) DEFAULT NULL COMMENT 'Date (unixtime) of the publication',
      `expires` int(11) DEFAULT NULL COMMENT 'Date (unixtime) of the expire',
      `status` char(32) DEFAULT NULL COMMENT 'Status of transaction',
      `comment` char(255) DEFAULT NULL COMMENT 'Comment',
      `errcode` int(11) DEFAULT NULL COMMENT 'Error code',
      `errmsg` text COMMENT 'Error message',
      PRIMARY KEY (`id`),
      KEY `I_ID` (`id`)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8

=head2 new

    my $store = new App::MonM::Notifier::Store(
        dsn => "DBI:mysql:database=monotifier;host=mysql.example.com",
        user => "username",
        password => "password",
        set => [
            "RaiseError        0",
            "PrintError        0",
            "mysql_enable_utf8 1",
        ],
    );

Creates DBI object

=head2 add

    $store->add(
        to      => $user,
        channel => $ch_name,
        subject => $subject,
        message => $message,
    ) or die($store->error);

Adds new recored

=head2 clean

    $store->clean or die($store->error);

Delete incorrect records (that are expired, skipped or failed)

=head2 del

    $store->del($id) or die($store->error);

Delete record by id

=head2 dsn

    my $dsn = $store->dsn;

Returns DSN string of current database connection

=head2 error

    my $error = $store->error;

Returns error message

    my $status = $store->error( "Error message" );

Sets error message if argument is provided.
This method in "set" context returns status of the operation as status() method.

=head2 get

    my %data = $store->get($id);

Returns data from database by id

=head2 getall

    my @table = $store->getall();
    my @table_100 = $store->getall(100);

Returns data from database with limit supporting

=head2 getByName

    my %data = $store->getByName($username, $ch_name);

Returns data from database by username and channel name

=head2 is_sqlite

    print $store->is_sqlite ? "Is SQLite" : "Is not SQLite"

Returns true if type of current database is SQLite

=head2 ping

    $store->ping ? 'OK' : 'Database session is expired';

Checks the connection to database

=head2 setError

    $store->setError($id, 102, "Error string")
        or die($store->error);

Sets error code and error message by id. See L<App::MonM::Notifier::Const>

=head2 setStatus

    $store->setStatus($id, JOB_EXPIRED, "Comment")
        or die($store->error);

Sets new status by id. See L<App::MonM::Notifier::Const>

=head2 status

    my $status = $store->status;
    my $status = $store->status( 1 ); # Sets the status value and returns it

Get/set BOOL status of the operation

=head2 truncate

    $store->truncate or die($store->error);

Delete all records

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK::DBI>, L<App::MonM>, L<App::MonM::Notifier>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '1.01';

use Carp;
use CTK::DBI;
use CTK::Util qw/ touch /;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use File::Spec;

use App::MonM::Const;
use App::MonM::Util qw/ set2attr /;

use App::MonM::Notifier::Const qw/ :jobs :functions EXPIRES /;
use App::MonM::Notifier::Util;

use constant {
    DB_FILENAME     => '.monotifier.db',
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
};

use constant MONOTIFIER_DDL => <<'DDL';
CREATE TABLE IF NOT EXISTS monotifier (
        `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        `to` CHAR(255), -- Recipient name
        `channel` CHAR(255), -- Recipient channel
        `subject` TEXT, -- Message subject
        `message` TEXT, -- Message content
        `pubdate` BIGINT(20), -- Date (unixtime) of the publication
        `expires` BIGINT(20), -- Date (unixtime) of the expire
        `status` CHAR(32), -- Status of transaction
        `comment` CHAR(255), -- Comment
        `errcode` INT(11), -- Error code
        `errmsg` TEXT -- Error message
    )
DDL

use constant MONOTIFIER_ADD => <<'DML';
INSERT INTO monotifier
    (`to`,`channel`,`subject`,`message`,`pubdate`,`expires`,`status`,`comment`,`errcode`,`errmsg`)
VALUES
    (?,?,?,?,?,?,?,?,?,?)
DML

use constant MONOTIFIER_GET_BY_NAME => <<'DML';
SELECT `id`,`to`,`channel`,`subject`,`message`,`pubdate`,`expires`,`status`,`comment`,`errcode`,`errmsg`
FROM monotifier
WHERE `status` = ? AND `to` = ? AND `channel` = ?
DML

use constant MONOTIFIER_SET_STATUS => <<'DML';
UPDATE monotifier
SET `status` = ?, `comment` = ?
WHERE `id` = ?
DML

use constant MONOTIFIER_SET_ERROR => <<'DML';
UPDATE monotifier
SET `status` = ?, `errcode` = ?, `errmsg` = ?
WHERE `id` = ?
DML

use constant MONOTIFIER_DEL => <<'DML';
DELETE FROM monotifier WHERE `id` = ?
DML

use constant MONOTIFIER_GET => <<'DML';
SELECT `id`,`to`,`channel`,`subject`,`message`,`pubdate`,`expires`,`status`,`comment`,`errcode`,`errmsg`
FROM monotifier
WHERE `id` = ?
DML

use constant MONOTIFIER_GETALL => <<'DML';
SELECT `id`,`to`,`channel`,`subject`,`pubdate`,`expires`,`status`,`comment`,`errcode`,`errmsg`
FROM monotifier
ORDER BY `id` DESC
DML

use constant MONOTIFIER_CLEAN => <<'DML';
DELETE FROM monotifier WHERE `status` IN ('EXPIRED', 'SKIP', 'ERROR') OR `expires` <= ?
DML

use constant MONOTIFIER_TRUNCATE => <<'DML';
DELETE FROM monotifier
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
    my $file = $args{file} || DB_FILENAME;
    my $dsn = $args{dsn} || sprintf(DEFAULT_DSN_MASK, $file);

    # DB
    my $db = new CTK::DBI(
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

    my $status = 1;
    my $error = "";
    if (!$db) {
        $error = sprintf("Can't init database \"%s\"", $dsn);
        $status = 0;
    } elsif (!$dbh) {
        $error = sprintf("Can't connect to database \"%s\": %s", $dsn, $DBI::errstr || "unknown error");
        $status = 0;
    } elsif ($fnew) {
        $db->execute(MONOTIFIER_DDL);
        $error = $dbh->errstr();
        $status = 0 if $dbh->err;
    }
    unless ($error) {
        unless ($dbh->ping) {
            $error = sprintf("Can't init database \"%s\". Ping failed: %s",
                $dsn, $dbh->errstr() || "unknown error");
            $status = 0;
        }
    }

    my $self = bless {
            file    => $file,
            issqlite=> $issqlite,
            dsn     => $dsn,
            error   => $error,
            dbi     => $db,
            expires => $args{expires} || EXPIRES,
            status  => $status,
        }, $class;

    return $self;
}
sub status {
    my $self = shift;
    my $value = shift;
    return fv2zero($self->{status}) unless defined($value);
    $self->{status} = $value ? 1 : 0;
    return $self->{status};
}
sub error {
    my $self = shift;
    my $value = shift;
    return uv2null($self->{error}) unless defined($value);
    $self->{error} = $value;
    $self->status($value ne "" ? 0 : 1);
    return $value;
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
sub is_sqlite {
    my $self = shift;
    return $self->{issqlite} ? 1 : 0;
}
sub add {
    my $self = shift;
    my %data = @_;
    return unless $self->ping;
    $self->error("");
    my $dbi = $self->{dbi};

    # Data
    my $pubdate = $data{pubdate} || time();
    my $expires = $pubdate + $self->{expires};

    # Delete too old records
    $dbi->execute('DELETE FROM monotifier WHERE `expires` <= ?', time());
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't delete old records: %s", uv2null($dbi->connect->errstr)));
        return;
    }

    # Добавляем запись в БД
    $dbi->execute(MONOTIFIER_ADD,
        $data{to},
        $data{channel},
        $data{subject}, $data{message},
        $pubdate, $expires,
        $data{status} || JOB_NEW,
        $data{comment},
        0, getErr(0),
    );
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't insert new record: %s", uv2null($dbi->connect->errstr)));
        return;
    }

    return 1;
}
sub getByName {
    my $self = shift;
    my ($name, $channel) = @_;
    $self->error("");
    my $dbi = $self->{dbi};

    # Get table
    my %tbl = $dbi->tableh("id", MONOTIFIER_GET_BY_NAME, JOB_NEW, $name, $channel);
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't select records: %s", uv2null($dbi->connect->errstr)));
        return;
    }

    # Update to PROGRESS status
    my $summary = 1;
    foreach my $id (keys %tbl) {
        $self->setStatus($id, JOB_PROGRESS) or do {$summary = 0};
    }
    return unless $summary;

    return %tbl;
}
sub setStatus {
    my $self = shift;
    my $id = shift || 0;
    my $status = shift || JOB_SKIP;
    my $comment = shift || sprintf("Modified at %s", scalar(localtime(time())));
    $self->error("");
    my $dbi = $self->{dbi};
    $dbi->execute(MONOTIFIER_SET_STATUS, $status, $comment, $id);
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't change status: %s", uv2null($dbi->connect->errstr)));
        return 0;
    }
    return 1;
}
sub setError {
    my $self = shift;
    my $id = shift || 0;
    my $code = shift || 1;
    my $error = sprintf(getErr($code), @_);
    $self->error("");
    my $dbi = $self->{dbi};

    $dbi->execute(MONOTIFIER_SET_ERROR, JOB_ERROR, $code, $error, $id);
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't set error: %s", uv2null($dbi->connect->errstr)));
        return 0;
    }
    return 1;
}
sub del {
    my $self = shift;
    my $id = shift || 0;
    my $dbi = $self->{dbi};
    $self->error("");

    $dbi->execute(MONOTIFIER_DEL, $id);
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't delete record: %s", uv2null($dbi->connect->errstr)));
        return 0;
    }
    return 1;
}
sub get {
    my $self = shift;
    my $id = shift || 0;
    my $dbi = $self->{dbi};
    $self->error("");

    my %rec = $dbi->recordh(MONOTIFIER_GET, $id);
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't get record: %s", uv2null($dbi->connect->errstr)));
        return ();
    }
    return %rec;
}
sub getall {
    my $self = shift;
    my $limit = shift || 0;
    my $dbi = $self->{dbi};
    $self->error("");

    my @tbl = $dbi->table(sprintf("%s%s", MONOTIFIER_GETALL,  $limit ? " LIMIT $limit" : "" ));
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't get records: %s", uv2null($dbi->connect->errstr)));
        return ();
    }
    return @tbl;
}
sub clean {
    my $self = shift;
    my $dbi = $self->{dbi};
    $self->error("");

    $dbi->execute(MONOTIFIER_CLEAN, time);
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't cleaning up: %s", uv2null($dbi->connect->errstr)));
        return 0;
    }
    return 1;
}
sub truncate {
    my $self = shift;
    my $dbi = $self->{dbi};
    $self->error("");

    $dbi->execute(MONOTIFIER_TRUNCATE);
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't truncate table: %s", uv2null($dbi->connect->errstr)));
        return 0;
    }
    return 1;
}

1;

__END__
