# Copyright (c) 2024 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2024 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Work with Tag databases

package Data::TagDB::Migration;

use v5.10;
use strict;
use warnings;

use Scalar::Util qw(weaken);
use Carp;

use Data::TagDB;

use parent 'Data::TagDB::WeakBaseObject';

use constant RE_UUID => qr/^[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}$/;

our $VERSION = v0.02;

my %table_defs = (
    tag      => 'CREATE TABLE IF NOT EXISTS tag (id INTEGER NOT NULL UNIQUE PRIMARY KEY AUTOINCREMENT);',
    hint     => 'CREATE TABLE IF NOT EXISTS hint (name VARCHAR(32) NOT NULL UNIQUE PRIMARY KEY, tag INTEGER NOT NULL REFERENCES tag(id));',
    metadata => 'CREATE TABLE IF NOT EXISTS metadata (tag INTEGER NOT NULL REFERENCES tag(id), relation INTEGER NOT NULL REFERENCES tag(id), context INTEGER NOT NULL REFERENCES tag(id) DEFAULT 0, type INTEGER NOT NULL REFERENCES tag(id) DEFAULT 0, encoding INTEGER NOT NULL REFERENCES tag(id) DEFAULT 0, data BLOB, UNIQUE(tag, relation, context, type, encoding, data));',
    relation => 'CREATE TABLE IF NOT EXISTS relation (tag INTEGER NOT NULL REFERENCES tag(id), relation INTEGER NOT NULL REFERENCES tag(id), context INTEGER NOT NULL REFERENCES tag(id) DEFAULT 0, related INTEGER NOT NULL REFERENCES tag(id), filter INTEGER NOT NULL REFERENCES tag(id) DEFAULT 0, UNIQUE(tag, relation, context, related, filter));',
);

my @indices = (
    [tag      => qw(id)],
    [hint     => qw(name)],
    [metadata => qw(tag)],
    [metadata => qw(tag relation)],
    [metadata => qw(data)],
    [relation => qw(tag)],
    [relation => qw(tag relation)],
    [relation => qw(related)],
);

my %indispensable = (
    'also-shares-identifier'    => 'ddd60c5c-2934-404f-8f2d-fcb4da88b633',
    'uuid'                      => '8be115d2-dc2f-4a98-91e1-a6e3075cbc31',
);

my %hints = map {$_ => $_ =~ tr/_/-/r} (
    qw(also_shares_identifier tagname uuid uri oid wikidata_identifier small_identifier),  # recommend
    qw(important no_direct has_type owned_by implies flagged_as using_namespace for_type), # friendly
);



sub upgrade {
    my ($self) = @_;
    $self->_create_tables;
    $self->_create_indices;
    $self->_create_hints_indispensable;
    $self->_create_hints;
}


sub create {
    my ($pkg, $first, @rest) = @_;
    my Data::TagDB $db;
    my __PACKAGE__ $self;
    my DBI $dbh;

    if (scalar(@rest) == 0 && eval { $first->can('prepare'); }) {
        $dbh = $first;
    } else {
        $dbh = DBI->connect($first, @rest) or croak 'Cannot connect to database';
    }

    $self = $pkg->_new(dbh => $dbh);

    $self->_create_tables;
    $self->_create_tag_null;
    $self->_create_hints_indispensable;

    $db = Data::TagDB->new($dbh);

    $self->{db} = $db;
    weaken($self->{db});

    $self->upgrade;

    return $db;
}


sub db {
    my ($self) = @_;
    return $self->{db};
}


sub dbh {
    my ($self) = @_;
    return $self->{dbh};
}


sub include {
    my ($self, @sources) = @_;
    foreach my $source (@sources) {
        if ($source eq 'Data::TagDB::WellKnown') {
            my Data::TagDB $db = $self->db;
            my Data::TagDB::WellKnown $wk = $db->wk;
            my Data::TagDB::Tag $asi = $wk->also_shares_identifier(1);
            my Data::TagDB::Tag $tagname = $wk->tagname(1);
            my Data::TagDB::Tag $sid = $wk->small_identifier(1);
            my Data::TagDB::Tag $default_type = $wk->default_type(1);
            my Data::TagDB::Tag $default_encoding = $wk->default_encoding(1);
            foreach my $name ($wk->_list) {
                my Data::TagDB::Tag $tag = $wk->_call($name, 1);
                my $info = $wk->_info($name);
                $db->create_metadata(tag => $tag, relation => $asi, type => $tagname, data_raw => $info->{tagname}) if defined $info->{tagname};
                $db->create_metadata(tag => $tag, relation => $asi, type => $sid,     data_raw => $info->{sid})     if defined $info->{sid};
                $db->create_relation(tag => $tag, relation => $default_type,     related => $wk->_call($info->{default_type},     1)) if defined $info->{default_type};
                $db->create_relation(tag => $tag, relation => $default_encoding, related => $wk->_call($info->{default_encoding}, 1)) if defined $info->{default_encoding};
            }
        } elsif ($source eq 'Data::URIID') {
            require Data::URIID;
            my Data::TagDB $db = $self->db;
            my Data::TagDB::WellKnown $wk = $db->wk;
            my Data::TagDB::Tag $uuid = $wk->uuid(1);
            my $extractor = Data::URIID->new;

            foreach my $class (qw(service type action)) {
                foreach my $ise ($extractor->known($class)) {
                    if ($ise =~ RE_UUID) {
                        $db->create_tag([$uuid => $ise]);
                    }
                }
            }
        } else {
            croak 'Invalid datasource: '.$source;
        }
    }
}

# ---- Private helpers ----

sub _new {
    my ($pkg, %opts) = @_;

    $opts{dbh} //= $opts{db}->dbh;

    return $pkg->SUPER::_new(%opts);
}

sub _create_table {
    my ($self, $name) = @_;
    my $query = $self->dbh->prepare($table_defs{$name});
    $query->execute;
    $query->finish;
}

sub _create_tables {
    my ($self) = @_;

    $self->_create_table($_) foreach qw(tag hint metadata relation);
}

sub _create_tag_null {
    my ($self) = @_;
    my DBI $dbh = $self->dbh;
    my $query = $dbh->prepare('INSERT INTO tag (id) VALUES (0);');
    $query->execute;
    $query->finish;
}

sub _create_hints_indispensable {
    my ($self) = @_;
    my DBI $dbh = $self->dbh;
    my %ids;

    # This loop is not efficient. However we only run it once per database. So no problem.

    foreach my $name (keys %indispensable) {
        my $query = $dbh->prepare('SELECT tag FROM hint WHERE name = ?');
        my $row;
        my $dbid;

        $query->execute($name);
        $row = $query->fetchrow_arrayref;
        $query->finish;

        next if defined($row) && defined($row->[0]) && $row->[0] > 0;

        $query = $dbh->prepare('INSERT INTO tag DEFAULT VALUES');
        $query->execute;
        $dbid = $query->last_insert_id;
        $query->finish;

        $query = $dbh->prepare('INSERT OR IGNORE INTO hint (name,tag) VALUES (?,?)');
        $query->execute($name, $dbid);
        $query->finish;

        $ids{$name} = $dbid;
    }

    {
        my $query = $dbh->prepare('INSERT OR IGNORE INTO metadata (tag,relation,context,type,encoding,data) VALUES (?,?,0,?,0,?)');
        foreach my $name (keys %indispensable) {
            my $dbid = $ids{$name};
            my $uuid = $indispensable{$name};

            $query->execute($dbid, $ids{'also-shares-identifier'}, $ids{uuid}, $uuid);
            $query->finish;
        }
    }
}

# This requies the database being fully up, so we have a $self->db.
sub _create_hints {
    my ($self) = @_;
    my DBI $dbh = $self->dbh;
    my Data::TagDB $db = $self->db;
    my Data::TagDB::WellKnown $wk = $db->wk;

    foreach my $name (keys %hints) {
        my Data::TagDB::Tag $tag = $wk->_call($name, 1);
        my $query = $dbh->prepare('INSERT OR IGNORE INTO hint (name,tag) VALUES (?,?)');
        $query->execute($hints{$name}, $tag->dbid);
        $query->finish;
    }
}

sub _create_index {
    my ($self, $table, @fields) = @_;
    my DBI $dbh = $self->dbh;
    my $query;

    die 'Bad parameters' unless scalar @fields;

    $query = $dbh->prepare('CREATE INDEX IF NOT EXISTS '.$table.'_'.join('_', @fields).' ON '.$table.' ('.join(',', @fields).');');
    $query->execute;
    $query->finish;
}

sub _create_indices {
    my ($self) = @_;
    $self->_create_index(@{$_}) foreach @indices;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagDB::Migration - Work with Tag databases

=head1 VERSION

version v0.02

=head1 SYNOPSIS

    use Data::TagDB;

    my Data::TagDB $db = Data::TagDB->new(...);
    $db->migration->upgrade;

    use Data::TagDB::Migration;
    my Data::TagDB $db = Data::TagDB::Migration->create(...);

Create with or upgrade database to current schema.

=head1 METHODS

=head2 upgrade

    $db->migration->upgrade;

Upgrade database to current schema.
Also ensures all required base objects are present.

=head2 create

    my Data::TagDB $db = Data::TagDB::Migration->create(...);

Creates a database and returns an handle to it.
This function takes the same arguments as L<Data::TagDB/new>.

=head2 db

    my Data::TagDB $db = $migration->db;

Returns the current L<Data::TagDB> object.

=head2 dbh

    my $dbh = $migration->dbh;

Returns the current L<DBI> connection.

=head2 include

    $migration->include(...);
    # e.g:
    $migration->include('Data::TagDB::WellKnown');

Includes data from a given source.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
