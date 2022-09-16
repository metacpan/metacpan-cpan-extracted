package App::MonM::Store; # $Id: Store.pm 108 2022-08-24 14:30:32Z abalama $
use strict;
use utf8;

=encoding utf8

=head1 NAME

App::MonM::Store - DBI interface for checkit's data storing

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use App::MonM::Store;

    my $store = App::MonM::Store->new(
        dsn => "DBI:mysql:database=monm;host=mysql.example.com",
        user => "username",
        password => "password",
        set => [
            "RaiseError        0",
            "PrintError        0",
            "mysql_enable_utf8 1",
        ],
    );
    die($store->error) if $store->error;

=head1 DESCRIPTION

DBI interface for checkit's data storing. This module provides store methods

=head2 new

    my $store = App::MonM::Store->new(
        dsn => "DBI:mysql:database=monm;host=mysql.example.com",
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
        name    => "foo",
        type    => "http",
        source  => "http://example.com",
        status  => 1,
        message => "Ok"
    ) or die $store->error;

Add new record on database

=head2 clean

    $store->clean(
        period => 600
    ) or die $store->error;

Delete too old records from database

=head2 del

    $store->del(
        id => 1
    ) or die $store->error;

Delete record from database

=head2 dsn

    my $dsn = $store->dsn;

Returns DSN string of current database connection

=head2 error

    my $error = $store->error;

Returns error message

    $store->error("Error message");

Sets error message if argument is provided.

=head2 get

    my %info = $store->get(
        name    => "foo"
    );

Gets information about file from database

Format:

    {
        id      => 1,
        time    => 123456789,
        name    => "foo"
        type    => "http",
        source  => "http://example.com"
        status  => 1,
        message => "Ok"
    }

=over 4

=item B<id>

The Record ID. Autoincremented value!

=item B<message>

The checking message

=item B<name>

Name of checkit section

=item B<source>

Source Name: URL, DSN or command

=item B<status>

Status of checking: 000-111 as binary notation

Default: 0

=item B<time>

Time of record insert

Default: time()

=item B<type>

Type of checkit source: http, dbi, command

Default: http

=back

=head2 is_sqlite

    print $store->is_sqlite ? "Is SQLite" : "Is not SQLite"

Returns true if type of current database is SQLite

=head2 getall

    my @files = $store->getall();

Returns list of all checkit values

Record format of return result: see L</get>

=head2 ping

    $store->ping ? 'OK' : 'Database session is expired';

Checks the connection to database

=head2 set

    $store->set(
        id      => 1,
        name    => "foo",
        type    => "http",
        source  => "http://example.com",
        status  => 1,
        message => "Ok"
    ) or die $store->error;

Update existing record on database

=head1 SEE ALSO

L<App::MonM>, L<CTK::DBI>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION /;
$VERSION = '1.01';

use Carp;
use CTK::DBI;
use CTK::Util qw/ touch /;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use File::Spec;

use App::MonM::Const;
use App::MonM::Util qw/ set2attr /;

use constant {
    DB_FILENAME         => 'monm.db',
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

use constant CHECKIT_DDL => <<'DDL';
CREATE TABLE IF NOT EXISTS monm (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    `time` NUMERIC DEFAULT 0,         -- time()
    `name` CHAR(255) DEFAULT NULL,    -- name of checkit section
    `type` CHAR(32) DEFAULT NULL,     -- http/dbi/command
    `source` CHAR(255) DEFAULT NULL,  -- URL/DSN/Command
    `status` INTEGER DEFAULT 0,       -- status value
    `message` TEXT DEFAULT NULL       -- message
)
DDL

use constant CHECKIT_INSERT => <<'DML';
INSERT INTO monm
    (`time`, `name`, `type`, `source`, `status`, `message`)
VALUES
    (?, ?, ?, ?, ?, ?)
DML

use constant CHECKIT_UPDATE => <<'DML';
UPDATE monm SET
    `time` = ?, `name` = ?, `type` = ?, `source` = ?, `status` = ?, `message` = ?
WHERE `id` = ?
DML

use constant CHECKIT_DELETE => <<'DML';
DELETE FROM monm WHERE `id` = ?
DML

use constant CHECKIT_CLEAN => <<'DML';
DELETE FROM monm WHERE `time` < ?
DML

use constant CHECKIT_SELECT => <<'DML';
SELECT `id`, `time`, `name`, `type`, `source`, `status`, `message`
FROM monm
WHERE `name` = ?
DML

use constant CHECKIT_SELECT_ALL => <<'DML';
SELECT `id`, `time`, `name`, `type`, `source`, `status`, `message`
FROM monm
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
        $db->execute(CHECKIT_DDL);
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
            error   => $error // "",
            dbi     => $db,
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
    return 0 unless $dbh->can('ping');
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

# CRUD Methods

sub add {
    my $self = shift;
    my %params = @_;
    return unless $self->ping;
    $self->error("");
    my $dbi = $self->{dbi};

    # Add
    $dbi->execute(CHECKIT_INSERT,
        time(),
        $params{name},
        $params{type},
        $params{source},
        $params{status} || 0,
        $params{message},
    )->finish;
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't insert new record: %s", uv2null($dbi->connect->errstr)));
        return;
    }

    return 1;
}
sub set {
    my $self = shift;
    my %params = @_;
    return unless $self->ping;
    $self->error("");
    my $dbi = $self->{dbi};

    # Update
    $dbi->execute(CHECKIT_UPDATE,
        time(),
        $params{name},
        $params{type},
        $params{source},
        $params{status} || 0,
        $params{message},
        $params{id},
    )->finish;
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't update record: %s", uv2null($dbi->connect->errstr)));
        return;
    }

    return 1;
}
sub del {
    my $self = shift;
    my %params = @_;
    return unless $self->ping;
    $self->error("");
    my $dbi = $self->{dbi};

    # Del
    $dbi->execute(CHECKIT_DELETE, $params{id})->finish;
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't delete record: %s", uv2null($dbi->connect->errstr)));
        return;
    }

    return 1;
}
sub get {
    my $self = shift;
    my %params = @_;
    return () unless $self->ping;
    $self->error("");
    my $dbi = $self->{dbi};

    # Get
    my $name = $params{name} || "";
    my %info = $dbi->recordh(CHECKIT_SELECT, $name);
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't get record: %s", uv2null($dbi->connect->errstr)));
        return ();
    }

    return %info;
}
sub getall {
    my $self = shift;
    my %params = @_;
    return () unless $self->ping;
    $self->error("");
    my $dbi = $self->{dbi};

    # Get table
    my %table = $dbi->tableh("id", CHECKIT_SELECT_ALL);
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't get records: %s", uv2null($dbi->connect->errstr)));
        return ();
    }

    # Out
    my @out = ();
    foreach my $k (sort {$a <=> $b} keys %table) {
        push @out, $table{$k};
    }
    return @out;
}
sub clean {
    my $self = shift;
    my %params = @_;
    return unless $self->ping;
    $self->error("");
    my $dbi = $self->{dbi};

    # Clean
    my $period = $params{period} || 0;
    $dbi->execute(CHECKIT_CLEAN, time() - $period)->finish;
    if ($dbi->connect->err) {
        $self->error(sprintf("Can't clean (truncate) table: %s", uv2null($dbi->connect->errstr)));
        return;
    }

    return 1;
}

1;

__END__
