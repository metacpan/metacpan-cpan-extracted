package TestDB;

use strict;
use warnings;
use Path::Class ();
use base 'DBIx::Class::Schema';

my $db = Path::Class::file(qw/t var test.db/);

sub init_schema {
  my $self = shift;
  $db->dir->rmtree if -e $db->dir;

  $db->dir->mkpath;

  my $dsn = 'dbi:SQLite:' . $db;
  my $schema = $self->connect($dsn);
    $schema->storage->on_connect_do([
        'PRAGMA synchronous = OFF',
        'PRAGMA temp_store = MEMORY'
    ]);

  $schema->deploy;

  return $schema;

}

sub DESTROY {
  $db->dir->rmtree if -e $db->dir;
}

__PACKAGE__->load_classes;

1;
