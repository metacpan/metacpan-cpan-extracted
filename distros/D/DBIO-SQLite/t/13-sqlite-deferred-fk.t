use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::SQLite::Test;

# This test verifies that with_deferred_fk_checks works on SQLite
# by using PRAGMA defer_foreign_keys = ON within a transaction.

my $schema = DBIO::SQLite::Test->init_schema(
  dsn         => 'dbi:SQLite::memory:',
  no_deploy   => 1,
  no_populate => 1,
);

# Enable foreign key enforcement (SQLite has them off by default)
$schema->storage->dbh_do(sub {
  $_[1]->do('PRAGMA foreign_keys = ON');
});

# Create parent and child tables with a FK constraint
$schema->storage->dbh_do(sub {
  my (undef, $dbh) = @_;

  $dbh->do(q{
    CREATE TABLE parent (
      id INTEGER PRIMARY KEY NOT NULL,
      name VARCHAR(100) NOT NULL
    )
  });

  $dbh->do(q{
    CREATE TABLE child (
      id INTEGER PRIMARY KEY NOT NULL,
      parent_id INTEGER NOT NULL,
      name VARCHAR(100) NOT NULL,
      FOREIGN KEY (parent_id) REFERENCES parent(id)
    )
  });
});

# First, verify that FK constraints are actually enforced:
# inserting a child with a nonexistent parent_id should fail.
throws_ok {
  $schema->storage->dbh_do(sub {
    $_[1]->do(q{INSERT INTO child (id, parent_id, name) VALUES (1, 999, 'orphan')});
  });
} qr/FOREIGN KEY constraint failed/i,
  'FK constraint is enforced - cannot insert child referencing nonexistent parent';

# Now test with_deferred_fk_checks: insert child before parent, then parent.
# This should succeed because FK checks are deferred until commit.
lives_ok {
  $schema->storage->with_deferred_fk_checks(sub {
    $schema->storage->dbh_do(sub {
      my (undef, $dbh) = @_;
      # Insert child first (parent_id=1 does not exist yet)
      $dbh->do(q{INSERT INTO child (id, parent_id, name) VALUES (1, 1, 'child row')});
      # Now insert the parent
      $dbh->do(q{INSERT INTO parent (id, name) VALUES (1, 'parent row')});
    });
  });
} 'with_deferred_fk_checks allows inserting child before parent';

# Verify both rows were actually inserted
my $parent_count = $schema->storage->dbh_do(sub {
  $_[1]->selectrow_array(q{SELECT COUNT(*) FROM parent});
});
is($parent_count, 1, 'parent row was committed');

my $child_count = $schema->storage->dbh_do(sub {
  $_[1]->selectrow_array(q{SELECT COUNT(*) FROM child});
});
is($child_count, 1, 'child row was committed');

# Verify the FK relationship is correct
my ($child_parent_id) = $schema->storage->dbh_do(sub {
  $_[1]->selectrow_array(q{SELECT parent_id FROM child WHERE id = 1});
});
is($child_parent_id, 1, 'child references the correct parent');

# Test that with_deferred_fk_checks still fails on commit if FK is violated
# (i.e., child references a parent that never gets inserted).
# The FK violation is caught at commit time and the transaction is rolled back.
throws_ok {
  $schema->storage->with_deferred_fk_checks(sub {
    $schema->storage->dbh_do(sub {
      $_[1]->do(q{INSERT INTO child (id, parent_id, name) VALUES (2, 999, 'orphan child')});
      # Never insert parent 999 -- should fail on commit
    });
  });
} qr/FOREIGN KEY constraint failed/i,
  'with_deferred_fk_checks still enforces FK on commit when constraint is violated';

done_testing;
