package App::MBUtiny::Collector::DBI; # $Id: DBI.pm 121 2019-07-01 19:51:50Z abalama $
use strict;
use utf8;

=encoding utf8

=head1 NAME

App::MBUtiny::Collector::DBI - Collector database interface

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use App::MBUtiny::Collector::DBI;

    my $dbi = new App::MBUtiny::Collector::DBI(
        dsn => "DBI:mysql:database=mbutiny;host=mysql.example.com",
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

Collector database interface

=head2 new

    my $dbi = new App::MBUtiny::Collector::DBI(
        dsn => "DBI:mysql:database=mbutiny;host=mysql.example.com",
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
        type => 0,
        name => "foo",
        addr => "127.0.0.1",
        status => 0,
        file => "foo-2019-06-25.tar.gz",
        size => 123456,
        md5 => "...",
        sha1 => "...",
        error => "...",
        comment => "...",
    ) or die $dbi->error;

Add new record on collector database

=head2 del

    $dbi->del(
        type => 0,
        name => "foo",
        addr => "127.0.0.1",
        file => "foo-2019-06-25.tar.gz",
    ) or die $dbi->error;

Delete record from collector database

=head2 dsn

    my $dsn = $dbi->dsn;

Returns DSN string of current collector database connection

=head2 error

    my $error = $dbi->error;
    $dbi->error("Error message");

Gets/sets error string

=head2 get

    my %info = $dbi->get(
        name => "foo",
        file => "foo-2019-06-25.tar.gz",
    );

Gets information about file from collector database

Format:

    {
        id      => 1,
        type    => 0,
        time    => 123456789,
        name    => "foo"
        addr    => "127.0.0.1",
        status  => 1,
        file    => "foo-2019-06-25.tar.gz",
        size    => 123456,
        md5     => "...",
        sha1    => "...",
        error   => "...",
        comment => "...",
    }

=over 4

=item B<id>

    Record ID. Autoincremented value!

=item B<type>

Type of collector:  0=internal, 1=external

Default: 0

=item B<time>

Time of record insert

Default: time()

=item B<name>

Name of mbutiny host

=item B<addr>

Client ip addr (IPv4/IPv6)

=item B<status>

Backup status: 0=false, 1=true

Default: 0

=item B<file>

Backup filename

=item B<size>

 Size of backup file

=item B<md5>

MD5-checksum of backup file

=item B<sha1>

SHA1-checksum of backup file

=item B<error>

Error message

=item B<comment>

Comment data

=back

=head2 is_sqlite

    print $dbi->is_sqlite ? "Is SQLite" : "Is not SQLite"

Returns true if type of current collector database is SQLite

=head2 list

    my @files = $dbi->list(
        name => "foo"
    );

Returns list of files by specified the name

Record format of return result: see L</get>

=head2 report

    my @files = $dbi->report(
        start => 123456789
    );

Returns list of all last backup files, starting at the specified the "start" value

Record format of return result: see L</get>

=head1 SEE ALSO

L<App::MBUtiny>, L<CTK::DBI>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION @EXPORT_OK/;
$VERSION = '1.00';

use Carp;
use CTK::DBI;
use CTK::Util qw/touch sharedstatedir/;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use File::Spec;

use constant {
    PREFIX                  => 'mbutiny',
    COLLECTOR_DB_FILENAME   => 'mbutiny.db',
    DEFAULT_ADDR            => '127.0.0.1',
    REPORT_PERIOD           => 24*60*60 + 1, # Yesterday + 1sec
    DEFAULT_DSN_MASK        => 'dbi:SQLite:dbname=%s',
    DEFAULT_DBI_ATTR        => {
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

use constant COLLECTOR_DDL  => <<'DDL';
CREATE TABLE IF NOT EXISTS mbutiny (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    `type` INTEGER DEFAULT 0,         -- 0=internal/1=external
    `time` NUMERIC DEFAULT 0,         -- time()
    `name` CHAR(255) DEFAULT NULL,    -- name of mbutiny host
    `addr` CHAR(45) DEFAULT NULL,     -- client ip addr
    `status` INTEGER DEFAULT 0,       -- backup status
    `file` CHAR(255) DEFAULT NULL,    -- backup filename
    `size` INTEGER DEFAULT 0,         -- size of backup file
    `md5` CHAR(32) DEFAULT NULL,      -- md5-checksum of backup file
    `sha1` CHAR(40) DEFAULT NULL,     -- sha1-checksum of backup file
    `error` TEXT DEFAULT NULL,        -- error message
    `comment` TEXT DEFAULT NULL       -- comment
)
DDL

use constant COLLECTOR_INSERT  => <<'DML';
INSERT INTO mbutiny
    (`type`, `time`, `name`, `addr`, `status`, `file`, `size`, `md5`, `sha1`, `error`, `comment`)
VALUES
    (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
DML

use constant COLLECTOR_DELETE  => <<'DML';
DELETE FROM mbutiny WHERE `type` = ? AND `name` = ? AND `file` = ? AND `addr` = ?
DML

use constant COLLECTOR_SELECT  => <<'DML';
SELECT `id`, `type`, `time`, `name`, `addr`, `status`, `file`, `size`, `md5`, `sha1`, `error`, `comment`
FROM mbutiny
WHERE `name` = ?
DML

use constant COLLECTOR_SELECT_FILE  => <<'DML';
SELECT `id`, `type`, `time`, `name`, `addr`, `status`, `file`, `size`, `md5`, `sha1`, `error`, `comment`
FROM mbutiny
WHERE `name` = ? AND `file` = ?
ORDER BY `time` DESC
LIMIT 1
DML

use constant COLLECTOR_SELECT_LASTFILE  => <<'DML';
SELECT `id`, `type`, `time`, `name`, `addr`, `status`, `file`, `size`, `md5`, `sha1`, `error`, `comment`
FROM mbutiny
WHERE `name` = ?
ORDER BY `time` DESC
LIMIT 1
DML

use constant COLLECTOR_REPORT  => <<'DML';
SELECT `id`, `type`, `time`, `name`, `addr`, `status`, `file`, `size`, `md5`, `sha1`, `error`, `comment`
FROM mbutiny
WHERE `time` > ?
DML

use base qw/Exporter/;
@EXPORT_OK = qw/
        COLLECTOR_DB_FILENAME
        COLLECTOR_DB_FILE
    /;

sub COLLECTOR_DB_FILE { File::Spec->catfile(sharedstatedir(), PREFIX, COLLECTOR_DB_FILENAME) }

sub new {
    my $class = shift;
    my %args = @_;
    unless ($args{dsn}) {
        my $dda = DEFAULT_DBI_ATTR;
        foreach (%$dda) {
            $args{$_} = $dda->{$_}
        }
    }
    my $file = $args{file} || COLLECTOR_DB_FILE();
    my $dsn = $args{dsn} || sprintf(DEFAULT_DSN_MASK, $file);

    # DB
    my $db = new CTK::DBI(
        -dsn    => $dsn,
        -debug  => 0,
        -username => $args{'user'},
        -passwprd => $args{'password'},
        -attr     => _attr($args{'set'}),
        $args{timeout} ? (
            -timeout_connect => $args{timeout}
            -timeout_request => $args{timeout}
        ) : (),
        $args{user} ? () : (),
    );
    my $dbh = $db->connect;

    # SQLite
    my $fnew = 0;
    my $issqlite = 0;
    if (($dsn =~ /SQLite/i)) {
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
        $db->execute(COLLECTOR_DDL);
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
    $db->execute(COLLECTOR_INSERT,
        $params{type} || 0,
        time(),
        $params{name},
        $params{addr} || DEFAULT_ADDR,
        $params{status} || 0,
        $params{file},
        $params{size} || 0,
        $params{md5},
        $params{sha1},
        $params{error},
        $params{comment},
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
    $db->execute(COLLECTOR_DELETE,
        $params{type} || 0,
        $params{name}, $params{file},
        $params{addr} || DEFAULT_ADDR,
    )->finish;

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
    my $file = $params{file} || "";
    my %info = ();
    if ($file) {
        %info = $db->recordh(COLLECTOR_SELECT_FILE, $name, $file);
    } else {
        %info = $db->recordh(COLLECTOR_SELECT_LASTFILE, $name);
    }
    if (my $dberr = $db->connect->errstr()) {
        $self->error($dberr || $DBI::errstr || "unknown error");
        return ();
    }
    return %info;
}
sub list {
    my $self = shift;
    my %params = @_;
    my $db = $self->{db};
    unless ($db) {
        $self->error(sprintf("Database \"%s\" connect failed", $self->dsn))
            unless $self->error;
        return ();
    }
    $self->error("");
    my %table = $db->tableh("id", COLLECTOR_SELECT, $params{name});
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
sub report {
    my $self = shift;
    my %params = @_;
    my $db = $self->{db};
    unless ($db) {
        $self->error(sprintf("Database \"%s\" connect failed", $self->dsn))
            unless $self->error;
        return ();
    }
    $self->error("");

    my $start = $params{start} || (time() - REPORT_PERIOD);
    my %table = $db->tableh("id", COLLECTOR_REPORT, $start);
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

sub _attr { # Sets attributes
    my $in = shift;
    my $attr = array($in => "set");
    my %attrs;
    foreach (@$attr) {
        $attrs{$1} = $2 if $_ =~ /^\s*(\S+)\s+(.+)$/;
    }
    return {%attrs};
}

1;

__END__
