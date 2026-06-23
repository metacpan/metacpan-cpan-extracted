use strict;
use warnings;
use Test::More;

# Offline DDL test -- no real DB2. Builds a tiny self-contained schema with a
# belongs_to relationship and asserts DBIO::DB2::DDL->install_ddl emits the FK
# as a *named* inline constraint with a deterministic name (fk_<table>_<cols>).
# DB2 enforces RI, so the install DDL must carry the FK; the deterministic name
# is what lets it round-trip with a stable identity for the FK diff (ADR 0005).
#
# Needs DBIO core on @INC: prove -I../dbio/lib -l t/35-ddl-fk.t

use_ok 'DBIO::DB2::DDL';

{
  package My::FK::Schema::Author;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('author');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 255 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->has_many('books', 'My::FK::Schema::Book', 'author_id');
}

{
  package My::FK::Schema::Book;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('book');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    author_id => { data_type => 'integer' },
    title     => { data_type => 'varchar', size => 255 },
  );
  __PACKAGE__->set_primary_key('id');
  # Default belongs_to (NO ACTION rules) -> FK must be emitted but without
  # ON DELETE / ON UPDATE clauses.
  __PACKAGE__->belongs_to('author', 'My::FK::Schema::Author', 'author_id');
}

{
  package My::FK::Schema::Review;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('review');
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1 },
    book_id => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key('id');
  # belongs_to with ON DELETE CASCADE -> must be rendered.
  __PACKAGE__->belongs_to('book', 'My::FK::Schema::Book',
    { 'foreign.id' => 'self.book_id' },
    { on_delete => 'CASCADE' });
}

{
  package My::FK::Schema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Author => 'My::FK::Schema::Author');
  __PACKAGE__->register_class(Book   => 'My::FK::Schema::Book');
  __PACKAGE__->register_class(Review => 'My::FK::Schema::Review');
}

my $ddl = DBIO::DB2::DDL->install_ddl('My::FK::Schema');
ok length $ddl, 'DDL generated';

# Topo-sort: author before book before review (FK dependency order).
like $ddl, qr/CREATE TABLE author.*CREATE TABLE book.*CREATE TABLE review/s,
  'tables created in FK-dependency order';

# book FK to author: named, deterministic, no ON DELETE/UPDATE (NO ACTION).
like $ddl,
  qr/CONSTRAINT fk_book_author_id FOREIGN KEY \(author_id\) REFERENCES author\(id\)/,
  'book FK emitted as named inline constraint with deterministic name';

# Default belongs_to carries no rules -> no ON DELETE / ON UPDATE on the book FK.
unlike $ddl, qr/fk_book_author_id FOREIGN KEY[^;]*ON DELETE/,
  'default belongs_to FK has no ON DELETE clause';

# review FK to book: ON DELETE CASCADE rendered.
like $ddl,
  qr/CONSTRAINT fk_review_book_id FOREIGN KEY \(book_id\) REFERENCES book\(id\) ON DELETE CASCADE/,
  'review FK renders ON DELETE CASCADE';

done_testing;
