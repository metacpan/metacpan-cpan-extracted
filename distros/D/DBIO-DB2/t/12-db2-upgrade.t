use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Optional::Dependencies ();

# LIVE ONLY (karr k41). $deploy->diff / ->upgrade against a real Db2, through
# the public DBIO::DB2::Deploy API and nothing else -- no introspector and no
# diff class is driven by hand here.
#
# Why this file exists: in a real diff BOTH models come out of SYSCAT (the live
# schema and the compare schema DBIO_TEST_<pid>), and that shape is not the one
# the offline tests used to feed the diff op classes:
#
#   * size is the catalog LENGTH -- INTEGER 4, SMALLINT 2, BIGINT 8, DATE 4,
#     and for TIMESTAMP length and scale (10 and 6);
#   * default_value is SYSCAT.COLUMNS.DEFAULT, which is SQL text already:
#     'new' with its quotes, 'it''s' with the apostrophe doubled, 0,
#     CURRENT TIMESTAMP;
#   * an identity column carries is_auto_increment.
#
# Rendered as if it were the result class shape, that gave "id" INTEGER(4)
# (SQL0104N: no table with an integer column could be created by upgrade),
# DEFAULT '''it''''s''' (accepted by the server, and then the column's default
# IS the text 'it''s' with the quotes in it, and every later diff wants to set
# it again), and a CREATE TABLE without GENERATED ALWAYS AS IDENTITY.
#
# So every block below ends on the two things an operator relies on: the diff
# after the upgrade is empty, and a row inserted afterwards holds the value the
# schema declares.
#
# No DROP COLUMN, no SET/DROP NOT NULL and no change of type here: those leave
# the table in reorg-pending state (SQL0668N rc 7) and the diff follows them
# with a REORG -- t/13-db2-upgrade-reorg.t (karr k42).

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_db2')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_db2');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

# Inline result classes, as in t/11-db2-fk.t: the defaults and the spread of
# types are the subject, and no shared test schema declares them.
{
  package DBIO::Test::Upgrade::Author;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('dbioup_author');
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1 },
    name    => { data_type => 'varchar', size => 100 },
    status  => { data_type => 'varchar', size => 20, default_value => 'new' },
    nick    => { data_type => 'varchar', size => 40, default_value => "it's", is_nullable => 1 },
    rating  => { data_type => 'integer', default_value => 0, is_nullable => 1 },
    small   => { data_type => 'smallint', is_nullable => 1 },
    big     => { data_type => 'bigint', is_nullable => 1 },
    score   => { data_type => 'decimal', size => '10,2', is_nullable => 1 },
    created => { data_type => 'timestamp', default_value => \'CURRENT TIMESTAMP', is_nullable => 1 },
    born    => { data_type => 'date', is_nullable => 1 },
    code    => { data_type => 'char', size => 3, is_nullable => 1 },
    bio     => { data_type => 'clob', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  sub db2_indexes { {
    dbioup_idx_author_status => { columns => ['status'] },
    dbioup_uq_author_name    => { columns => ['name'], unique => 1 },
  } }
}

{
  package DBIO::Test::Upgrade::Book;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('dbioup_book');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    author_id => { data_type => 'integer' },
    title     => { data_type => 'varchar', size => 255, default_value => "it's" },
    pages     => { data_type => 'integer', default_value => 0, is_nullable => 1 },
    price     => { data_type => 'decimal', size => '10,2', is_nullable => 1 },
    published => { data_type => 'date', is_nullable => 1 },
    created   => { data_type => 'timestamp', default_value => \'CURRENT TIMESTAMP', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(author => 'DBIO::Test::Upgrade::Author', 'author_id',
    { on_delete => 'CASCADE' });
  sub db2_indexes { { dbioup_idx_book_title => { columns => ['title'] } } }
}

{
  package DBIO::Test::Upgrade::Note;
  use strict; use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('dbioup_note');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    label => { data_type => 'varchar', size => 20, is_nullable => 1 },
    state => { data_type => 'varchar', size => 10, default_value => 'new' },
    body  => { data_type => 'varchar', size => 50, default_value => "it's" },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package DBIO::Test::Upgrade::Schema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DB2');
  __PACKAGE__->register_class(Author => 'DBIO::Test::Upgrade::Author');
  __PACKAGE__->register_class(Book   => 'DBIO::Test::Upgrade::Book');
  __PACKAGE__->register_class(Note   => 'DBIO::Test::Upgrade::Note');
}

use DBIO::DB2::Deploy;

my $schema = DBIO::Test::Upgrade::Schema->connect($dsn, $user, $pass);

my $dbh = eval { $schema->storage->dbh }
  or plan skip_all => "Cannot reach DB2: $@";

my $deploy = DBIO::DB2::Deploy->new(schema => $schema);

# Raw SQL in this file quotes its identifiers: the DDL does (karr k28), and an
# unquoted name folds to uppercase and misses the object.
sub drop_test_tables {
  local $dbh->{PrintError} = 0;
  eval { $dbh->do(qq{DROP TABLE "$_"}) }
    for qw(dbioup_book dbioup_note dbioup_author);
}

# The compare schema of this process. DBIO::DB2::Deploy drops it itself; the
# count is asserted at the end, and END clears one a failed run left behind.
my $COMPARE_SCHEMA = "DBIO_TEST_$$";
sub compare_schema_count {
  my ($n) = $dbh->selectrow_array(
    'SELECT COUNT(*) FROM syscat.schemata WHERE schemaname = ?', undef, $COMPARE_SCHEMA);
  return $n;
}

END {
  if ($dbh && $dbh->{Active}) {
    drop_test_tables();
    $deploy->_drop_test_schema($dbh, $COMPARE_SCHEMA)
      if eval { compare_schema_count() };
  }
}

# The operations of a fresh $deploy->diff, or the reason there is none.
sub diff_ops {
  my $diff = eval { $deploy->diff };
  return (undef, $@) unless $diff;
  return [ @{ $diff->operations } ];
}

# The point every block comes back to: nothing is left to do.
sub diff_is_empty {
  my ($name) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my ($ops, $err) = diff_ops();
  if (!$ops) {
    fail $name;
    diag "diff died: $err";
    return;
  }
  is scalar(@$ops), 0, $name
    or diag join "\n", 'operations still pending:', map { $_->as_sql } @$ops;
}

drop_test_tables();

# ============================================================================
# 1. install, then diff: the schema just installed has nothing to change.
#    Every type and every kind of default the three tables declare goes
#    through SYSCAT on both sides here.
# ============================================================================
lives_ok { $deploy->install } 'install deploys the three tables';

diff_is_empty('diff right after install has no operations');

# ============================================================================
# 2. A column missing from a live table that already has a row, and a default
#    that differs. The live table is written by hand, so that no DROP COLUMN is
#    needed to get there.
# ============================================================================
$dbh->do('DROP TABLE "dbioup_note"');
$dbh->do(q{
  CREATE TABLE "dbioup_note" (
    "id" INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1),
    "label" VARCHAR(20),
    "state" VARCHAR(10) NOT NULL DEFAULT 'old',
    PRIMARY KEY ("id")
  )
});
$dbh->do(q{INSERT INTO "dbioup_note" ("label", "state") VALUES ('before', 'kept')});

{
  my ($ops, $err) = diff_ops();
  my @col = grep { $_->isa('DBIO::DB2::Diff::Column') } @{ $ops || [] };
  is_deeply [ sort map { join ' ', $_->action, $_->column_name } @col ],
    [ 'add body', 'alter state' ],
    'diff sees the missing column and the changed default, and nothing else'
    or diag $err // join "\n", map { $_->as_sql } @$ops;
}

lives_ok { $deploy->upgrade } 'upgrade adds the column and sets the default';

diff_is_empty('diff after the column upgrade has no operations');

{
  my ($body) = eval { local $dbh->{PrintError} = 0; $dbh->selectrow_array(q{SELECT "body" FROM "dbioup_note" WHERE "label" = 'before'}) };
  is $body, "it's", 'the row that was there gets the declared default in the added column';

  my $note = eval { $schema->resultset('Note')->create({ label => 'after' }) };
  diag "insert into the upgraded table failed: $@" unless $note;
  my $row = $note ? $schema->resultset('Note')->find($note->id) : undef;
  is $row && $row->get_column('body'), "it's", 'a new row gets the declared default in the added column';
  is $row && $row->get_column('state'), 'new', '... and the changed default in the altered one';
}

# ============================================================================
# 3. A table missing from the live database. upgrade has to create it out of
#    the compare schema's catalog model: integer identity primary key, a
#    string default with an apostrophe, a numeric default, DECIMAL(10,2), DATE,
#    TIMESTAMP with CURRENT TIMESTAMP, a named FK and an index.
# ============================================================================
$dbh->do('DROP TABLE "dbioup_book"');

{
  my ($ops, $err) = diff_ops();
  ok $ops && scalar(grep { $_->isa('DBIO::DB2::Diff::Table') && $_->action eq 'create'
                           && $_->table_name eq 'dbioup_book' } @$ops) == 1,
    'diff sees the missing table as one CREATE TABLE'
    or diag $err // join "\n", map { $_->as_sql } @$ops;
}

lives_ok { $deploy->upgrade } 'upgrade creates the missing table';

diff_is_empty('diff after creating the table has no operations');

{
  my $author = $schema->resultset('Author')->create({ name => 'a1' });
  my @book = map {
    my $n = $_;
    eval { $schema->resultset('Book')->create({ author_id => $author->id }) }
      or diag "insert $n into the created table failed: $@";
  } 1, 2;

  ok $book[0] && $book[0]->id, 'a row in the created table gets an identity value';
  ok $book[1] && $book[1]->id && $book[1]->id != $book[0]->id,
    '... and the next row a different one';

  my $row = $book[0] ? $schema->resultset('Book')->find($book[0]->id) : undef;
  is $row && $row->get_column('title'), "it's",
    'the string default of the created table is the declared value, not its SQL text';
  is $row && $row->get_column('pages'), 0, '... the numeric default is the declared number';
  ok $row && defined $row->get_column('created'), '... and CURRENT TIMESTAMP is evaluated';

  throws_ok {
    local $dbh->{PrintError} = 0;
    $dbh->do('INSERT INTO "dbioup_book" ("author_id") VALUES (2147483647)');
  } qr/SQL0530N/, 'the created table enforces its foreign key';
}

# ============================================================================
# 4. Nothing of the compare deploy is left behind.
# ============================================================================
is compare_schema_count(), 0, "no compare schema $COMPARE_SCHEMA is left in the database";

done_testing;
