package My::Journal::Model;

use strict;
use warnings;
use Carp;

use DBI;

#-------

sub new {
    my ($class, %args) = @_;
    
    my $sqlite_db_path = $args{ dbpath } or croak 'path to SQLite DB file required';

    # Connect to database...
    my $dbh = DBI->connect( "dbi:SQLite:dbname=$sqlite_db_path",
        { AutoCommit => 1, RaiseError => 1, ShowErrorStatement => 1 }
    );
    bless { _dbh => $dbh }, $class;
}

sub dbh { $_[0]->{_dbh} }

#-------

sub insert_entry {
    my ($self, $entry_text) = @_;

    my $dbh = $self->dbh();

    my $entry_id;
    $dbh->begin_work(); # transaction (to get id of last-inserted record)
    eval {
        $dbh->do( q{
            INSERT INTO journal_entry (entry_text)
            VALUES (?)
        }, undef, $entry_text );
        
        my $e = $dbh->selectrow_arrayref( 'SELECT MAX(id) FROM journal_entry' );
        $entry_id = $e->[0];

        $dbh->commit();
    };
    if( $@ ) { eval { $dbh->rollback() } }

    return $entry_id;
}

sub delete_entry {
    my ($self, $id) = @_;

    my $dbh = $self->dbh();

    my $rows_affected = $dbh->do( q{
        DELETE FROM journal_entry
        WHERE id = ?
    }, undef, $id );

    return 1;
}

sub insert_tag {
    my ($self, $tag_text) = @_;

    my $dbh = $self->dbh();

    $dbh->do( q{
        INSERT INTO tag (tag_text)
        VALUES (?)
    }, undef, $tag_text );

    return 1;
}

sub add_tag_to_entry {
    my ($self, $entry_id, $tag_text) = @_;

    my $dbh = $self->dbh();

    $dbh->begin_work(); # transaction
    eval {
        my $tag_id;
        my $tag = $dbh->selectrow_arrayref(
            "SELECT id FROM tag WHERE tag_text = ?", undef, $tag_text
        );
        unless( defined $tag ) {
            # Tag does not exist already...
            $self->insert_tag( $tag_text );

            my $t = $dbh->selectrow_arrayref( 'SELECT MAX(id) FROM tag' );
            $tag_id = $t->[0];
        }
        $tag_id ||= $tag->[0];

        # Add (pre-existing or new) tag to journal entry...
        $dbh->do(
            'INSERT INTO entry2tag (entry_id, tag_id) VALUES (?, ?)',
            undef, $entry_id, $tag_id
        );
        $dbh->commit;
    };
    if( $@ ) { eval { $dbh->rollback() } }

    return 1;
}

sub remove_tag_from_entry {
    my ($self, $entry_id, $tag_id) = @_;

    my $dbh = $self->dbh();
    my $sth = $dbh->prepare_cached( q{
        DELETE FROM entry2tag
        WHERE entry_id = ?
        AND tag_id = ?
    } );
    $sth->execute( $entry_id, $tag_id );

    return 1;
}

sub clear_tags_from_entry {
    my ($self, $entry_id) = @_;

    my $dbh = $self->dbh();

    $dbh->do( q{
        DELETE FROM entry2tag
        WHERE entry_id = ?
    }, undef, $entry_id );

    return 1;
}

#-------

sub get_tag_id_by_name {
    my ($self, $tag_text) = @_;

    my $dbh = $self->dbh();

    my $t = $dbh->selectrow_arrayref(
        'SELECT id FROM tag WHERE tag_text = ?', undef, $tag_text
    );
    my $tag_id;
    if( defined $t ) {
        $tag_id = $t->[0];
    }
    return $tag_id;
}

sub entry_by_id {
    my ($self, $id) = @_;

    my $dbh = $self->dbh();

    my $sth = $dbh->prepare_cached( q{
        SELECT  id, entry_text
        FROM    journal_entry
        WHERE   id = ?
    } );
    $sth->execute( $id );

    my $row = $sth->fetchrow_hashref();
    $sth->finish();

    return $row;
}

sub entries_by_tag {
    my ($self, $tag_text) = @_;

    my $dbh = $self->dbh();

    my $sth = $dbh->prepare_cached( q{
        SELECT      e.id, e.entry_text
        FROM        journal_entry e
        INNER JOIN  entry2tag e2t ON (e2t.entry_id = e.id)
        INNER JOIN  tag t ON (t.id = e2t.tag_id)
        WHERE       t.tag_text = ?
    } );
    $sth->execute( $tag_text );
    my @entries;
    while( my $entry = $sth->fetchrow_hashref() ) {
        push @entries, $entry;
    }
    $sth->finish();
    return @entries;
}

sub all_entries {
    my ($self) = @_;

    my $dbh = $self->dbh();

    my $sth = $dbh->prepare_cached( q{
        SELECT  e.id, e.entry_text
        FROM    journal_entry e
    } );
    $sth->execute();

    my @rows;
    while( my $row = $sth->fetchrow_hashref() ) {
        push @rows, $row;
    }
    return @rows;
}

sub tags_by_entry_id {
    my ($self, $entry_id) = @_;

    my $dbh = $self->dbh();

    my $sth = $dbh->prepare_cached( q{
        SELECT      t.tag_text
        FROM        tag t
        INNER JOIN  entry2tag e2t ON (e2t.tag_id = t.id)
        WHERE       e2t.entry_id = ?
    } );
    $sth->execute( $entry_id );
    my $tags = $sth->fetchall_arrayref();

    return map { $_->[0] } @$tags;
}

#-------
1;

__END__

=pod

=head1 NAME

My::Journal::Model - Example model class for My::Journal demo app.

=head1 DEPENDENCIES

DBI

DBD::SQLite

=cut
