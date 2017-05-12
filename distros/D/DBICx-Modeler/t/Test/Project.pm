package t::Test::Project;

use strict;
use warnings;

use Directory::Scratch;
use DBICx::Modeler;
use t::Test::Project::Schema;

my $scratch = Directory::Scratch->new;
sub scratch {
    return $scratch;
}

sub schema {
    my $class = shift;
    my $file = $class->scratch->base->file( 'schema.db' );
    my $schema = t::Test::Project::Schema->connect( 'dbi:SQLite:' . $file );
    unless (-s $file) {
        $schema->storage->dbh->do(<<_END_) or die;
CREATE TABLE artist (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    name                TEXT,
    insert_datetime     DATE NOT NULL DEFAULT current_timestamp
);
_END_
        $schema->storage->dbh->do(<<_END_) or die;
CREATE TABLE cd (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    artist              INTEGER,
    title               TEXT,
    insert_datetime     DATE NOT NULL DEFAULT current_timestamp
);
_END_
        $schema->storage->dbh->do(<<_END_) or die;
CREATE TABLE track (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    cd                  INTEGER,
    title               TEXT,
    insert_datetime     DATE NOT NULL DEFAULT current_timestamp
);
_END_
    }
    return $schema;
}

sub modeler {
    my $self = shift;
    return DBICx::Modeler->new( schema => $self->schema, namespace => '+t::Test::Project::Model', @_ );
}

1;
