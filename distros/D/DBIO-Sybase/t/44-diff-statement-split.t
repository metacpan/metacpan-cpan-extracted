use strict;
use warnings;
use Test::More;

# Every statement a Sybase diff op renders ends in ';' (karr k49).
#
# Core joins the ops of a diff with "\n" (DBIO::Diff::Base::as_sql), and the
# apply path splits that text on ';' and nothing else
# (DBIO::Deploy::Base::_execute_ddl -> DBIO::SQL::Util::_split_statements).
# An op without a terminator therefore glues itself to the next one, and the
# whole run reaches ASE as ONE batch. ASE compiles a batch before running any
# of it, so a correctly ordered migration still fails as a whole -- met live on
# ASE 16.0 SP02: DROP INDEX / ALTER TABLE ... REPLACE / ALTER TABLE ... DROP,
# the column drop rejected with Msg 4939 ("being used by an index") because the
# index drop ahead of it had not run yet. Sent one by one, all three succeed.
#
# What is pinned is the property the server needs, not the character: the
# migration text of a many-op diff falls apart into exactly the statements the
# ops stand for, one per $dbh->do, in the diff's dependency order.

use DBIO::SQL::Util ();
use DBIO::Sybase::Diff;
use DBIO::Sybase::Deploy;
use DBIO::Sybase::Storage::ASE;

sub tbl { +{ table_name => $_[0], kind => 'table' } }
sub col {
  my ($name, %o) = @_;
  +{ column_name => $name, data_type => $o{type} // 'integer',
     size => $o{size}, not_null => $o{not_null} // 0,
     default_value => $o{default}, is_pk => 0 };
}
sub idx {
  my ($name, %o) = @_;
  +{ index_name => $name, is_unique => $o{unique} // 0,
     columns => $o{columns} // [] };
}

# One op of every kind that renders SQL, two of them (the column alter that
# moves size AND default, the index alter) rendering two statements each.
my $source = {
  tables  => { probe => tbl('probe'), book => tbl('book'), old_t => tbl('old_t') },
  columns => {
    probe => [
      col('id',   not_null => 1),
      col('name', type => 'varchar', size => 32, not_null => 1, default => 'a'),
      col('code', type => 'varchar', size => 10),
      col('wide', type => 'varchar', size => 10, default => 'x'),
    ],
    book  => [ col('id', not_null => 1), col('author_id') ],
    old_t => [ col('id', not_null => 1) ],
  },
  indexes => {
    probe => {
      probe_code_idx => idx('probe_code_idx', columns => ['code']),
      probe_wide_idx => idx('probe_wide_idx', columns => ['wide']),
    },
    book => {},
  },
  foreign_keys => {
    book => [ { constraint_name => 'fk_book_old', from_columns => ['author_id'],
                to_table => 'probe', to_columns => ['id'] } ],
  },
};
my $target = {
  tables  => { probe => tbl('probe'), book => tbl('book'), fresh => tbl('fresh') },
  columns => {
    probe => [
      col('id',    not_null => 1),
      col('name',  type => 'varchar', size => 32, not_null => 1, default => 'b'),
      col('wide',  type => 'varchar', size => 20, default => 'y'),
      col('extra', type => 'varchar', size => 5),
    ],
    book  => [ col('id', not_null => 1), col('author_id') ],
    fresh => [ col('id', not_null => 1) ],
  },
  indexes => {
    probe => { probe_wide_idx => idx('probe_wide_idx', unique => 1, columns => ['wide']) },
    book  => {},
    fresh => {},
  },
  foreign_keys => {
    book => [ { from_columns => ['author_id'], to_table => 'fresh', to_columns => ['id'] } ],
  },
};

my @expected = (
  'ALTER TABLE book DROP CONSTRAINT fk_book_old',
  "CREATE TABLE fresh (\n  id INT NOT NULL\n)",
  'DROP TABLE old_t',
  'DROP INDEX probe.probe_code_idx',
  'ALTER TABLE probe ADD extra VARCHAR(5) NULL',
  "ALTER TABLE probe REPLACE name DEFAULT 'b'",
  'ALTER TABLE probe MODIFY wide VARCHAR(20) NULL',
  "ALTER TABLE probe REPLACE wide DEFAULT 'y'",
  'ALTER TABLE probe DROP code',
  'DROP INDEX probe.probe_wide_idx',
  'CREATE UNIQUE INDEX probe_wide_idx ON probe (wide)',
  'ALTER TABLE book ADD CONSTRAINT fk_book_author_id FOREIGN KEY (author_id) REFERENCES fresh (id)',
);

my $diff = DBIO::Sybase::Diff->new(source => $source, target => $target);
is(scalar @{ $diff->operations }, 10, 'the fixture yields ten ops');

my $sql = $diff->as_sql;
is_deeply([ DBIO::SQL::Util::_split_statements($sql) ], \@expected,
  'as_sql splits into exactly one entry per statement, in dependency order')
  or diag $sql;

# Every op on its own, too: a terminator on the op, not an accident of which
# op happens to follow which in the fixture above.
for my $op (@{ $diff->operations }) {
  like($op->as_sql, qr/;\z/, ref($op) . ' ends its SQL with ;');
}

# ... and the path apply() actually takes: core's _execute_ddl over a handle
# that only records, one $dbh->do per statement.
{
  package Split::Dbh;
  sub new { bless { AutoCommit => 1, log => [] }, shift }
  sub do  { my ($self, $sql) = @_; push @{ $self->{log} }, $sql; 1 }
}
{
  package Split::Schema;
  sub new     { bless { storage => $_[1] }, $_[0] }
  sub storage { $_[0]{storage} }
}

my $storage = DBIO::Sybase::Storage::ASE->new;
my $dbh     = Split::Dbh->new;
$storage->_dbh($dbh);
my $deploy  = DBIO::Sybase::Deploy->new(schema => Split::Schema->new($storage));
{
  local $SIG{__WARN__} = sub {};   # core's one-shot "not atomic" notice (t/42)
  $deploy->_execute_ddl($dbh, $sql);
}
is_deeply($dbh->{log}, \@expected,
  '_execute_ddl hands ASE one statement per $dbh->do, never a glued batch');

done_testing;
