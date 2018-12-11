package
    TimePieceDB;

use strict;
use warnings;

use Path::Class ();

use parent 'DBIx::Class::Schema';

my $db = Path::Class::file(qw/t var time_piece.db/);

sub init_schema {
    my ($self) = @_;
    $db->dir->rmtree if -e $db->dir;

    $db->dir->mkpath;

    my $schema = $self->connect( 'DBI:SQLite:' . $db );

    $schema->storage->on_connect_do([
        'PRAGMA synchronous = OFF',
        'PRAGMA temp_store = MEMORY',
    ]);

    $schema->deploy;

    return $schema;
}

sub DESTROY {
    $db->dir->rmtree if -e $db->dir;
}

__PACKAGE__->load_classes();

1;
