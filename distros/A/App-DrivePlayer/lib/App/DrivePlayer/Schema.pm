package App::DrivePlayer::Schema;

use strict;
use warnings;
use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces();

# Connect to a SQLite database at $path, configure pragmas, and deploy
# the schema if the tables do not yet exist.
sub connect_and_deploy {
    my ($class, $path) = @_;

    my $schema = $class->connect(
        "dbi:SQLite:dbname=$path", '', '',
        {
            sqlite_unicode => 1,
            on_connect_do  => [
                'PRAGMA journal_mode=WAL',
                'PRAGMA foreign_keys=ON',
            ],
        },
    );

    # Deploy only when the database is new (tracks table absent)
    my $dbh    = $schema->storage->dbh;
    my @tables = $dbh->tables(undef, undef, 'tracks', 'TABLE');
    unless (@tables) {
        $schema->deploy({ add_drop_table => 0 });
    }

    # Migrate: add columns introduced after initial deploy
    my %existing = map { $_->[1] => 1 }
        @{ $dbh->selectall_arrayref('PRAGMA table_info(tracks)') };
    for my $col (qw( genre comment )) {
        next if $existing{$col};
        $dbh->do("ALTER TABLE tracks ADD COLUMN $col TEXT");
    }
    unless ($existing{metadata_fetched}) {
        $dbh->do('ALTER TABLE tracks ADD COLUMN metadata_fetched INTEGER NOT NULL DEFAULT 0');
    }

    # Migrate: drop the unused composer column (SQLite >= 3.35)
    $dbh->do('ALTER TABLE tracks DROP COLUMN composer') if $existing{composer};

    return $schema;
}

1;

__END__

=head1 NAME

App::DrivePlayer::Schema - DBIx::Class schema for the DrivePlayer SQLite database

=head1 DESCRIPTION

A L<DBIx::Class::Schema> subclass that owns the C<scan_folders>, C<folders>,
and C<tracks> result classes.  Use L</connect_and_deploy> rather than the
inherited C<connect> to ensure the SQLite pragmas and tables are set up
correctly.

=head1 METHODS

=head2 connect_and_deploy

  my $schema = App::DrivePlayer::Schema->connect_and_deploy($path);

Connect to the SQLite database at C<$path>, enable WAL journal mode and
foreign-key enforcement, and deploy the schema (create tables) if the
database is new.  Returns the connected schema object.

=cut
