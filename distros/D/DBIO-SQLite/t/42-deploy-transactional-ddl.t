use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBI;

use DBIO::SQLite::Storage;

# F02 / F10 -- the transactional_ddl capability DBIO::SQLite::Storage declares.
# Offline: no DSN, no server, no DBIO_TEST_* anything. The declaration is a
# class-level fact, and the rest of this file runs against an in-memory SQLite.
#
# Asserting the VALUE alone would prove nothing here. Core's default for an
# undeclared capability is 0 as well (DBIO::Storage::DBI::Capabilities defines
# _determine_supports_transactional_ddl => 0), so the first assertion below is
# green with nothing declared at all. The get_inherited assertion is the actual
# tripwire: it is defined only for a value this class set itself.
#
# It matters more here than anywhere else in the family, because SQLite is the
# one engine whose 0 is NOT an engine limitation -- it does transactional DDL,
# and the driver still answers no. The second half of this file is why.

# --- the declaration --------------------------------------------------------

is(DBIO::SQLite::Storage->_use_transactional_ddl, 0,
  'transactional_ddl is 0 -- the deploy loop must not be bracketed in txn_do');

isnt(DBIO::SQLite::Storage->get_inherited('_use_transactional_ddl'), undef,
  '... and the driver states it, rather than inheriting core\'s default');

SKIP: {
  eval { require DBD::SQLite; 1 } or skip 'DBD::SQLite required', 8;

  # --- the engine fact the declaration rests on -----------------------------
  #
  # PRAGMA foreign_keys is a no-op inside a transaction ("foreign key
  # constraint enforcement may only be enabled or disabled when there is no
  # pending BEGIN or SAVEPOINT"), and SQLite reports that by accepting the
  # statement and ignoring it -- no error, no warning. A rebuild whose FK
  # window is opened by such a statement therefore loses that window silently
  # the moment anything brackets it.
  {
    my $dbh = DBI->connect('dbi:SQLite::memory:', '', '',
      { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
    $dbh->do('PRAGMA foreign_keys = ON');

    $dbh->begin_work;
    lives_ok { $dbh->do('PRAGMA foreign_keys=OFF') }
      'PRAGMA foreign_keys=OFF inside a transaction does not complain';
    is(scalar $dbh->selectrow_array('PRAGMA foreign_keys'), 1,
      '... and does not take either -- enforcement is still on');
    $dbh->rollback;

    $dbh->do('PRAGMA foreign_keys=OFF');
    is(scalar $dbh->selectrow_array('PRAGMA foreign_keys'), 0,
      'outside a transaction the same statement takes -- this is the whole difference');
    $dbh->disconnect;
  }

  # --- and what that costs on the real upgrade path -------------------------
  #
  # Same shape as t/37-rebuild.t part C: a table another table references,
  # rebuilt because a column becomes NOT NULL, on a connection with foreign
  # keys enforced. Run twice against one database -- once with the capability
  # forced true on the storage (tier 1), which is what a future "SQLite does
  # have transactional DDL, so this should be 1" cleanup would amount to, and
  # once with the force cleared so the class declaration answers again.
  {
    package TxnDdl::V1;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('SQLite');
  }
  {
    package TxnDdl::V1::Result::Author;
    use base 'DBIO::Core';
    __PACKAGE__->table('author');
    __PACKAGE__->add_columns(
      id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
      name => { data_type => 'text',    is_nullable => 1 },
    );
    __PACKAGE__->set_primary_key('id');
  }
  {
    package TxnDdl::V1::Result::Book;
    use base 'DBIO::Core';
    __PACKAGE__->table('book');
    __PACKAGE__->add_columns(
      id        => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
      author_id => { data_type => 'integer', is_nullable => 0 },
      title     => { data_type => 'text',    is_nullable => 0 },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->belongs_to('author' => 'TxnDdl::V1::Result::Author', 'author_id');
  }
  TxnDdl::V1->register_class(Author => 'TxnDdl::V1::Result::Author');
  TxnDdl::V1->register_class(Book   => 'TxnDdl::V1::Result::Book');

  {
    package TxnDdl::V2;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('SQLite');
  }
  {
    package TxnDdl::V2::Result::Author;
    use base 'DBIO::Core';
    __PACKAGE__->table('author');
    __PACKAGE__->add_columns(
      id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
      name => { data_type => 'text',    is_nullable => 0 },   # NOT NULL -> rebuild
    );
    __PACKAGE__->set_primary_key('id');
  }
  {
    package TxnDdl::V2::Result::Book;
    use base 'DBIO::Core';
    __PACKAGE__->table('book');
    __PACKAGE__->add_columns(
      id        => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
      author_id => { data_type => 'integer', is_nullable => 0 },
      title     => { data_type => 'text',    is_nullable => 0 },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->belongs_to('author' => 'TxnDdl::V2::Result::Author', 'author_id');
  }
  TxnDdl::V2->register_class(Author => 'TxnDdl::V2::Result::Author');
  TxnDdl::V2->register_class(Book   => 'TxnDdl::V2::Result::Book');

  require DBIO::SQLite::Deploy;

  my $schema = TxnDdl::V1->connect('dbi:SQLite::memory:', '', '', { AutoCommit => 1 });
  $schema->storage->dbh->do('PRAGMA foreign_keys = ON');
  DBIO::SQLite::Deploy->new(schema => $schema)->install;

  my $a = $schema->resultset('Author')->create({ name => 'Adams' });
  my $b = $schema->resultset('Book')->create({
    author_id => $a->id, title => 'Hitchhikers',
  });

  my $v2      = TxnDdl::V2->connect(sub { $schema->storage->dbh });
  my $deploy2 = DBIO::SQLite::Deploy->new(schema => $v2);
  my $diff    = $deploy2->diff;
  like($diff->as_sql, qr/__dbio_rebuild/, 'the upgrade routes through a rebuild');

  # The storage is resolved by now (install touched the dbh), so this is the
  # SQLite driver's own storage and the force lands in tier 1 above the class
  # declaration -- DBIO::Deploy::Base::_execute_ddl then brackets the whole
  # statement list in txn_do.
  my $storage = $v2->storage;
  $storage->_use_transactional_ddl(1);

  throws_ok { $deploy2->apply($diff) } qr/FOREIGN KEY constraint failed/i,
    'bracketed in txn_do the rebuild dies -- its PRAGMA foreign_keys=OFF never took, '
  . 'so DROP TABLE hit the reference from book';

  # Clearing the force hands the question back to the declaration (undef
  # deletes the tier-1 slot rather than tombstoning it), and the same diff
  # applies cleanly against the same database -- the failed attempt rolled
  # back, which is the one thing transactional DDL did deliver.
  $storage->_use_transactional_ddl(undef);
  is($storage->_use_transactional_ddl, 0,
    'clearing the force falls through to the class declaration, not to a tombstone');

  lives_ok { $deploy2->apply($diff) }
    'statement at a time, with AutoCommit on, the identical rebuild applies';

  is($schema->resultset('Book')->find($b->id)->author->name, 'Adams',
    'cross-table reference intact after the rebuild');
}

done_testing;
