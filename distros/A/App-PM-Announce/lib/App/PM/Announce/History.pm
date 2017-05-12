package App::PM::Announce::History;

use warnings;
use strict;

use Moose;
use DBI;
use DBIx::Simple;
use SQL::Script;
use JSON;
my $json = JSON->new->allow_blessed(1)->convert_blessed(1);

has app => qw/is ro isa App::PM::Announce required 1/, handles => [qw/ logger /];

has history_file => qw/is ro lazy_build 1/;
sub _build_history_file {
    return shift->app->home_dir->file( 'history' );
}

has _dbh => qw/is ro lazy_build 1/;
sub _build__dbh {
    my $self = shift;

    my $history_file = $self->history_file;
    my $dbh = DBI->connect( "dbi:SQLite:dbname=$history_file", '', '');

    return $dbh;
}

sub dbh {
    my $self = shift;

    my $history_file = $self->history_file;
    $self->_deploy unless -f $history_file && -s _;

    return $self->_dbh;
}

has db => qw/is ro isa DBIx::Simple lazy_build 1/;
sub _build_db {
    my $self = shift;
    return DBIx::Simple->new( $self->dbh );
}

sub _deploy {
    my $self = shift;

    my $dbh = $self->_dbh;
    my $script = SQL::Script->new(split_by => qr/\n\s*-{2,4}\n/);
    $script->read(\<<_END_);
CREATE TABLE event (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    uuid                TEXT NOT NULL,
    data                TEXT NOT NULL DEFAULT '{}',
    insert_datetime     DATE NOT NULL DEFAULT current_timestamp,
    update_datetime     DATE,

    UNIQUE (uuid)
);
---
CREATE TRIGGER event_update_trigger AFTER UPDATE ON event
BEGIN
    UPDATE event SET update_datetime = current_timestamp;
END;
_END_

    for my $statement ($script->statements) {
        $dbh->do( $statement) or die $dbh->errstr;
    }
}

sub insert {
    my $self = shift;
    my $uuid = shift;
    my %data = @_;

    my $db = $self->db;
    my $data = $json->encode( \%data );

    $db->query( 'INSERT INTO event (uuid, data) VALUES (?, ?)', $uuid, $data ) or die $db->error;
}

sub find_or_insert {
    my $self = shift;
    my $uuid = shift;

    my $result = $self->_fetch( $uuid );
    return $result if $result;
    $self->insert( $uuid );
    return $self->fetch( $uuid );
}

sub _fetch {
    my $self = shift;
    my $uuid = shift;

    my $db = $self->db;
    return $self->inflate( $db->query( 'SELECT * FROM event WHERE uuid = ? LIMIT 1', $uuid )->hash );
}

sub fetch {
    my $self = shift;
    my $uuid = shift;

    my $result = $self->_fetch( $uuid );
    die "Couldn't fetch $uuid" unless $result;

    return $result;
}

sub update {
    my $self = shift;
    my $uuid = shift;
    my %data = @_;

    my $db = $self->db;
    my $result = $self->fetch( $uuid ) or die "Couldn't find record for $uuid";
    my $data = $json->encode( { %{ $result->{data} }, %data } );

    $db->query( 'UPDATE event SET data = ? WHERE uuid = ?', $data, $uuid ) or die $db->error;
}

sub inflate {
    my $self = shift;
    my $result = shift;
    $result->{data} = $json->decode( $result->{data} ) if $result && $result->{data};
    return $result;
}

sub all {
    my $self = shift;

    my $db = $self->db;
    return map { $self->inflate( $_ ) } $db->query( 'SELECT * FROM event ORDER BY insert_datetime' )->hashes;
}

sub find {
    my $self = shift;
    my $query = shift;

    my $db = $self->db;
    return $self->inflate( $db->query( 'SELECT * FROM event WHERE uuid LIKE ? ORDER BY insert_datetime DESC LIMIT 1', "$query%" )->hash );
}

1;
__END__

CREATE TRIGGER match_player_nm_trigger AFTER INSERT ON match_player
BEGIN
    UPDATE match_player SET nm = (SELECT coalesce(max(nm) + 1, 1) FROM match_player WHERE mtch_id = new.mtch_id) WHERE rowid = new.rowid;
END;

[% PRIMARY_KEY = "INTEGER PRIMARY KEY AUTOINCREMENT" %]
[% KEY = "INTEGER" %]

    id                  [% PRIMARY_KEY %],

[% CLEAR %]
--
CREATE TABLE topic (
    id                  [% PRIMARY_KEY %],
    site                TEXT KEY,
    site_topic_id       TEXT KEY,
    title               TEXT,
    category            TEXT,
    remote_post_count   INT DEFAULT 0,
    rank                INT DEFAULT 0,
    rank_dtime          DATE,
    insert_dtime        DATE NOT NULL DEFAULT current_timestamp,
    update_dtime        DATE,
    appendix            TEXT NOT NULL DEFAULT '{}',
    spam_score          INT,
    status              TEXT,

    UNIQUE (site_topic_id)
);
--



1;
