package App::MonM::Store; # $Id: Store.pm 76 2019-07-07 05:20:28Z abalama $
use strict;
use utf8;

=encoding utf8

=head1 NAME

App::MonM::Store - DBI interface for checkit's data storing

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use App::MonM::Store;

    my $dbi = new App::MonM::Store(
        dsn => "DBI:mysql:database=monm;host=mysql.example.com",
        user => "username",
        password => "password",
        set => [
            "RaiseError        0",
            "PrintError        0",
            "mysql_enable_utf8 1",
        ],
    );
    print STDERR $dbi->error if $dbi->error;

=head1 DESCRIPTION

DBI interface for checkit's data storing

=head2 new

    my $dbi = new App::MonM::Store(
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

    $dbi->add(
        name    => "foo",
        type    => "http",
        source  => "http://example.com",
        status  => 1,
        message => "Ok"
    ) or die $dbi->error;

Add new record on database

=head2 clean

    $dbi->clean(
        period => 600
    ) or die $dbi->error;

Delete too old records from database

=head2 del

    $dbi->del(
        id => 1
    ) or die $dbi->error;

Delete record from database

=head2 dsn

    my $dsn = $dbi->dsn;

Returns DSN string of current database connection

=head2 error

    my $error = $dbi->error;
    $dbi->error("Error message");

Gets/sets error string

=head2 get

    my %info = $dbi->get(
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

    print $dbi->is_sqlite ? "Is SQLite" : "Is not SQLite"

Returns true if type of current database is SQLite

=head2 getall

    my @files = $dbi->getall();

Returns list of all checkit values

Record format of return result: see L</get>

=head2 set

    $dbi->set(
        id      => 1,
        name    => "foo",
        type    => "http",
        source  => "http://example.com",
        status  => 1,
        message => "Ok"
    ) or die $dbi->error;

Update existing record on database

=head1 SEE ALSO

L<App::MonM>, L<CTK::DBI>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION /;
$VERSION = '1.00';

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

    my $error = "";
    if (!$db) {
        $error = sprintf("Can't init database \"%s\"", $dsn);
    } elsif (!$dbh) {
        $error = sprintf("Can't connect to database \"%s\": %s", $dsn, $DBI::errstr || "unknown error");
    } elsif ($fnew) {
        $db->execute(CHECKIT_DDL);
        $error = $dbh->errstr();
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
            db      => $db,
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
    my %params = @_;
    my $db = $self->{db};
    unless ($db) {
        $self->error(sprintf("Database \"%s\" connect failed", $self->dsn))
            unless $self->error;
        return 0;
    }
    $self->error("");
    $db->execute(CHECKIT_INSERT,
        time(),
        $params{name},
        $params{type},
        $params{source},
        $params{status} || 0,
        $params{message},
    )->finish;
    if (my $dberr = $db->connect->errstr()) {
        $self->error($dberr || $DBI::errstr || "unknown error");
        return 0;
    }
    return 1;
}
sub set {
    my $self = shift;
    my %params = @_;
    my $db = $self->{db};
    unless ($db) {
        $self->error(sprintf("Database \"%s\" connect failed", $self->dsn))
            unless $self->error;
        return 0;
    }
    $self->error("");
    $db->execute(CHECKIT_UPDATE,
        time(),
        $params{name},
        $params{type},
        $params{source},
        $params{status} || 0,
        $params{message},
        $params{id},
    )->finish;
    if (my $dberr = $db->connect->errstr()) {
        $self->error($dberr || $DBI::errstr || "unknown error");
        return 0;
    }
    return 1;
}
sub del {
    my $self = shift;
    my %params = @_;
    my $db = $self->{db};
    unless ($db) {
        $self->error(sprintf("Database \"%s\" connect failed", $self->dsn))
            unless $self->error;
        return 0;
    }
    $self->error("");
    $db->execute(CHECKIT_DELETE, $params{id})->finish;

    if (my $dberr = $db->connect->errstr()) {
        $self->error($dberr || $DBI::errstr || "unknown error");
        return 0;
    }
    return 1;
}
sub get {
    my $self = shift;
    my %params = @_;
    my $db = $self->{db};
    unless ($db) {
        $self->error(sprintf("Database \"%s\" connect failed", $self->dsn))
            unless $self->error;
        return;
    }
    $self->error("");
    my $name = $params{name} || "";
    my %info = $db->recordh(CHECKIT_SELECT, $name);

    if (my $dberr = $db->connect->errstr()) {
        $self->error($dberr || $DBI::errstr || "unknown error");
        return ();
    }
    return %info;
}
sub getall {
    my $self = shift;
    my %params = @_;
    my $db = $self->{db};
    unless ($db) {
        $self->error(sprintf("Database \"%s\" connect failed", $self->dsn))
            unless $self->error;
        return ();
    }
    $self->error("");
    my %table = $db->tableh("id", CHECKIT_SELECT_ALL);
    if (my $dberr = $db->connect->errstr()) {
        $self->error($dberr || $DBI::errstr || "unknown error");
        return ();
    }
    my @out = ();
    foreach my $k (sort {$a <=> $b} keys %table) {
        push @out, $table{$k};
    }
    return @out;
}
sub clean {
    my $self = shift;
    my %params = @_;
    my $db = $self->{db};
    unless ($db) {
        $self->error(sprintf("Database \"%s\" connect failed", $self->dsn))
            unless $self->error;
        return 0;
    }
    $self->error("");
    my $period = $params{period} || 0;
    $db->execute(CHECKIT_CLEAN, time() - $period)->finish;

    if (my $dberr = $db->connect->errstr()) {
        $self->error($dberr || $DBI::errstr || "unknown error");
        return 0;
    }
    return 1;
}

1;

__END__
