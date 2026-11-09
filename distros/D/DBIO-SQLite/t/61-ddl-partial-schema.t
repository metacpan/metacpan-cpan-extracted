use strict;
use warnings;
use Test::More;
use Test::Exception;

# A schema that registers only some of its result classes still deploys.
#
# A belongs_to names the class it points at. Where that class is not
# registered with the schema that is deployed, there is no source to ask for
# the table's name, and DBIO::SQLite::DDL writes no FOREIGN KEY for that
# relationship; the keys to the classes that are registered stay. This was
# held by the SQL::Translator parser test (t/99dbic_sqlt_parser.t, "partial
# dbic schema parsing") until that path went away; nothing held it for the
# native DDL.
#
# The full schema over the same result classes is the control: there the
# relationship does write its key, so the missing one is missing because of
# the missing class and for no other reason.

BEGIN {
  eval { require DBD::SQLite; 1 }
    or plan skip_all => 'DBD::SQLite required';
}

use DBIO::SQLite::DDL;

{
  package PartialDDL::Result::Author;
  use base 'DBIO::Core';
  __PACKAGE__->table('author');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package PartialDDL::Result::Shelf;
  use base 'DBIO::Core';
  __PACKAGE__->table('shelf');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package PartialDDL::Result::Book;
  use base 'DBIO::Core';
  __PACKAGE__->table('book');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    author_id => { data_type => 'integer', is_nullable => 0 },
    shelf_id  => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(author => 'PartialDDL::Result::Author', 'author_id');
  __PACKAGE__->belongs_to(shelf  => 'PartialDDL::Result::Shelf',  'shelf_id');
}
{
  package PartialDDL::Full;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
  __PACKAGE__->register_class(Author => 'PartialDDL::Result::Author');
  __PACKAGE__->register_class(Shelf  => 'PartialDDL::Result::Shelf');
  __PACKAGE__->register_class(Book   => 'PartialDDL::Result::Book');
}
{
  package PartialDDL::Partial;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
  __PACKAGE__->register_class(Shelf => 'PartialDDL::Result::Shelf');
  __PACKAGE__->register_class(Book  => 'PartialDDL::Result::Book');
}

my $TO_AUTHOR = 'FOREIGN KEY ("author_id") REFERENCES "author"("id")';
my $TO_SHELF  = 'FOREIGN KEY ("shelf_id") REFERENCES "shelf"("id")';

is_deeply(
  fk_lines('PartialDDL::Full'), [ $TO_AUTHOR, $TO_SHELF ],
  'every class registered: both relationships write their key',
);

my $lines;
lives_ok { $lines = fk_lines('PartialDDL::Partial') }
  'the DDL of a schema without the author class is written';

is_deeply(
  $lines, [ $TO_SHELF ],
  '... with the key to the class that is there, and none to the one that is not',
);

my $schema = PartialDDL::Partial->connect('dbi:SQLite::memory:', undef, undef, {
  on_connect_call => 'use_foreign_keys',
});

lives_ok { $schema->deploy } 'the partial schema deploys';

my $dbh = $schema->storage->dbh;

is_deeply(
  $dbh->selectcol_arrayref(
    q{SELECT name FROM sqlite_master WHERE type = 'table'
      AND name NOT LIKE 'sqlite_%' ORDER BY name},
  ),
  [qw( book shelf )],
  'only the tables of the registered classes exist',
);

is_deeply(
  [ map { $_->{table} } @{ $dbh->selectall_arrayref(
    q{PRAGMA foreign_key_list("book")}, { Slice => {} },
  ) } ],
  [ 'shelf' ],
  'the deployed table holds the one key',
);

# By execution, on a connection that enforces foreign keys: the column of the
# unregistered class takes any value, the other one is still checked.
is(scalar $dbh->selectrow_array('PRAGMA foreign_keys'), 1,
  'foreign keys are enforced on this connection');

my $shelf = $schema->resultset('Shelf')->create({})->id;

lives_ok {
  $schema->resultset('Book')->create({ author_id => 4711, shelf_id => $shelf });
} 'a book of an author nobody deployed is stored';

throws_ok {
  $schema->resultset('Book')->create({ author_id => 4711, shelf_id => $shelf + 1 });
} qr/FOREIGN KEY constraint failed/,
  'a book on a shelf that is not there is refused';

done_testing;

# The FOREIGN KEY lines install_ddl writes for the book table, as written.
sub fk_lines {
  my ($class) = @_;
  for my $stmt (split /\n\n/, DBIO::SQLite::DDL->install_ddl($class)) {
    next unless $stmt =~ /\ACREATE TABLE "book" \(/;
    return [ map { /^\s*(FOREIGN KEY.*?),?$/ ? $1 : () } split /\n/, $stmt ];
  }
  return undef;
}
