use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Schema;
use DBIO::Oracle::Deploy;
use DBIO::Oracle::Introspect;
use DBIO::Oracle::Diff;
use DBIO::Oracle::Identifier;

# LIVE (karr k36). What DBIO::Oracle::Deploy does to a real Oracle schema.
#
# The card: "_build_target_model: the first CREATE TABLE commits implicitly,
# ROLLBACK TO SAVEPOINT fails (ORA-01086, swallowed in the eval), the test
# deploy stays in the live schema." This file ran that against a server, and
# it held (section 4). The strategy was replaced (ADR 0010): the desired state
# is deployed into a temporary user, DBIO_TMP_<pid>_<n>, made and dropped on
# a connection of its own. What is asserted against the server:
#
#   IS      diff and upgrade work through the temp user: the diff of a schema
#           against the state it already has is empty, a missing column is
#           found and added by upgrade, a second upgrade finds nothing to do
#           (2, 5). A transaction the caller has open stays open and
#           uncommitted, no DBIO_TMP_ user stays behind -- also when the
#           deploy in it dies -- and nothing of the test deploy is left in
#           the live schema (2, 3, 5).
#   WHY     the statements of the old strategy, replayed in their order (4):
#           ORA-01086, the test deploy stays, the caller's row is committed.
#           It is the measured reason for ADR 0010 and what a savepoint
#           strategy has to get past.
#
#   1. install, the public path that deploys into the connected schema: what
#      it leaves in the schema, what a second install and an install over an
#      older schema do, that it commits a transaction the caller had open,
#      and that a NOT NULL column with a default is created and the default
#      is what an insert gets (1e, karr k45; measured 2026-10-07, same
#      server), that the unique constraints of a source are enforced (1f,
#      karr k46) and that the names are those the storage asks for, with the
#      trigger that feeds the auto-increment column and the foreign key of a
#      belongs_to (1a, karr k42).
#   2. diff and upgrade: empty on an up-to-date schema, ALTER for a changed
#      table, the caller's transaction, no leftover user.
#   3. _build_target_model by itself: the model of the desired state, and
#      nothing of the test deploy in the live schema.
#   4. The old strategy, replayed (WHY).
#   5. upgrade end to end, and the failure path.
#
# What the diff makes of a table only the desired schema has (karr k37) is
# t/55-diff-index-live.t, not claimed here; the schemas of 2 and 5 differ in a
# table both sides have.
#
# The older state of a schema is made the way this driver would have made it:
# by install, from a schema class that lacks a column and two tables. That
# matters -- install writes its names quoted, as the result classes spell
# them (lower case; karr k42), and only a table of that exact name is in the
# way of the next install (1b, 1c).
#
# Measured 2026-10-05 against Oracle Database 23ai Free (23.26.3), with
# DBD::Oracle 1.95; sections 2, 3 and 5 on 2026-10-25, same server. What this
# file does NOT claim:
#
#   * anything about DBIO::Oracle::Diff built directly from two models, or
#     about apply given such a diff beyond what 5 applies;
#     t/55-diff-index-live.t is about the first.
#   * a connected user without CREATE USER / DROP USER: the test user has
#     them; the refusal is pinned offline (t/58-deploy-temp-user.t).
#   * that a failed statement always commits. Measured beside this file: a
#     CREATE TABLE that fails on the name (ORA-00955) has committed, one that
#     does not parse (ORA-00931) has not. 1d rests on the first.
#   * the error texts on another server version. ORA-00911, ORA-00942,
#     ORA-00955, ORA-01086 and ORA-03076 are what 23.26 says.
#   * anything about the recycle bin beyond "nothing of this test is in it".

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_ORA_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_ORA_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

plan skip_all => 'Test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_oracle')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_oracle');

alarm 300;   # no handler: an OCI call that hangs ends the run instead of never

# Core says once per process that Oracle's DDL loop is not atomic
# (t/52-deploy-transactional-ddl.t pins it). Known; anything else is asserted
# away at the end.
my @warnings;
local $SIG{__WARN__} = sub {
  return if $_[0] =~ /\Anon-transactional DDL on DBIO::Oracle::Deploy\b/;
  push @warnings, $_[0];
  warn $_[0];
};

# ------------------------------------------------------------ the schemas
#
# V1 is the older state: one table, without "email". V2 is the desired one:
# that table with the column, a table whose source sorts before it and one
# that sorts after it -- the install DDL goes through the sources in that
# order, and where it stops is what 1c and 4b look at.

{
  package T::K36::V1::Author;
  use base 'DBIO::Core';
  __PACKAGE__->table('k36_live_author');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K36::V2::Account;
  use base 'DBIO::Core';
  __PACKAGE__->table('k36_live_account');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K36::V2::Author;
  use base 'DBIO::Core';
  __PACKAGE__->table('k36_live_author');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    name  => { data_type => 'varchar', size => 100, is_nullable => 1 },
    email => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  # karr k46: the unique constraint of the source is what install writes
  # (the column_info key is_unique it once looked at is set by nobody)
  __PACKAGE__->add_unique_constraint(['email']);
  # the has_many of the belongs_to below: its key is ON DELETE CASCADE
  __PACKAGE__->has_many(books => 'T::K36::V2::Book', 'author_id');
}

{
  package T::K36::V2::Book;
  use base 'DBIO::Core';
  __PACKAGE__->table('k36_live_book');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer' },
    author_id => { data_type => 'integer' },
    title     => { data_type => 'varchar', size => 200, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(author => 'T::K36::V2::Author', 'author_id');
}

{
  package T::K36::V1;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
  __PACKAGE__->register_class(Author => 'T::K36::V1::Author');
}

{
  package T::K36::V2;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
  __PACKAGE__->register_class($_ => "T::K36::V2::$_") for qw(Account Author Book);
}

# V1 with the column V2 has, and nothing else: the desired state of the diff
# and upgrade tests (2, 3, 5), where both sides have the table.
{
  package T::K36::V1B::Author;
  use base 'DBIO::Core';
  __PACKAGE__->table('k36_live_author');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    name  => { data_type => 'varchar', size => 100, is_nullable => 1 },
    email => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K36::V1B;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
  __PACKAGE__->register_class(Author => 'T::K36::V1B::Author');
}

# A table of its own for 1e (karr k45): columns that are NOT NULL and have a
# default -- a literal, a false literal, an expression -- and a nullable one
# with a default beside them.
{
  package T::K36::Defaults::Defaulted;
  use base 'DBIO::Core';
  __PACKAGE__->table('k36_live_defaulted');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer' },
    state => { data_type => 'varchar', size => 20, is_nullable => 0, default_value => 'new' },
    hits  => { data_type => 'integer', is_nullable => 0, default_value => 0 },
    twice => { data_type => 'integer', is_nullable => 0, default_value => \'1 + 1' },
    note  => { data_type => 'varchar', size => 20, is_nullable => 1, default_value => 'none' },
    # karr k47: the default is a SQL literal -- an apostrophe is doubled, a
    # number is not quoted, a string that only looks like one keeps its quotes
    quip   => { data_type => 'varchar', size => 20, is_nullable => 1, default_value => "it's" },
    lead   => { data_type => 'varchar', size => 20, is_nullable => 1, default_value => '007' },
    varnum => { data_type => 'varchar', size => 20, is_nullable => 1, default_value => 10 },
    ratio  => { data_type => 'numeric', size => [5, 2], is_nullable => 1, default_value => 0.5 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K36::Defaults;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
  __PACKAGE__->register_class(Defaulted => 'T::K36::Defaults::Defaulted');
}

# A table of its own for 1f (karr k46): unique constraints, one-column and
# two-column, and two that Oracle would refuse if install wrote them (the
# primary key's columns again; an earlier constraint's columns again).
{
  package T::K36::Uniq::Row;
  use base 'DBIO::Core';
  __PACKAGE__->table('k36_live_unique');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    code => { data_type => 'varchar', size => 10 },
    a    => { data_type => 'integer' },
    b    => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(k36_live_u_code => ['code']);
  __PACKAGE__->add_unique_constraint(k36_live_u_pair => [qw(a b)]);
  __PACKAGE__->add_unique_constraint(k36_live_u_pk   => ['id']);
  __PACKAGE__->add_unique_constraint(k36_live_u_code2 => ['code']);
}

{
  package T::K36::Uniq;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
  __PACKAGE__->register_class(Row => 'T::K36::Uniq::Row');
}

# A deploy object on a connection of its own, the way an application has one.
sub deploy_of {
  my ($schema_class) = @_;
  return DBIO::Oracle::Deploy->new(
    schema => $schema_class->connect($dsn, $user, $pass),
  );
}

# ------------------------------------------------- looking at the server
#
# A third connection, plain DBI, for setup and for looking at what the server
# really holds: from another session, and through nothing of this driver. A
# reader never waits for a writer on Oracle, so an uncommitted row of the
# other session is simply not there for this one.
my $admin;
sub admin {
  return $admin ||= DBI->connect($dsn, $user, $pass, {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
  });
}

sub server_value { ( admin()->selectrow_array(@_) )[0] }
sub server_rows  { admin()->selectall_arrayref(@_) }

my $OWN = q{LIKE 'K36\_LIVE%' ESCAPE '\'};

# Everything of this test the data dictionary holds, one line each: tables
# with their columns, primary, unique and foreign keys, indexes, sequences,
# triggers. A name Oracle made up is not a fact about the deploy and is
# written as (system).
sub snapshot {
  my @is;

  my (%columns, @tables);
  for my $row (@{ server_rows(qq{
    SELECT table_name, column_name, data_type, char_length, nullable
    FROM user_tab_columns WHERE UPPER(table_name) $OWN
    ORDER BY table_name, column_id
  }) }) {
    my ($table, $column, $type, $chars, $nullable) = @$row;
    push @tables, $table unless $columns{$table};
    push @{ $columns{$table} }, join ' ', $column,
      ( $chars ? "$type($chars)" : $type ), ( $nullable eq 'N' ? 'NOT NULL' : () );
  }
  push @is, map { "TABLE $_ (" . join(', ', @{ $columns{$_} }) . ')' } @tables;

  my (%key, @keys);
  for my $row (@{ server_rows(qq{
    SELECT c.constraint_type, c.table_name, c.constraint_name, c.generated,
           cc.column_name
    FROM user_constraints c
    JOIN user_cons_columns cc ON cc.constraint_name = c.constraint_name
    WHERE c.constraint_type IN ('P', 'U', 'R') AND UPPER(c.table_name) $OWN
    ORDER BY c.table_name, c.constraint_type, c.constraint_name, cc.position
  }) }) {
    my ($type, $table, $name, $generated, $column) = @$row;
    $name = '(system)' if $generated eq 'GENERATED NAME';
    my $kind = { P => 'PRIMARY KEY', U => 'UNIQUE', R => 'FOREIGN KEY' }->{$type};
    my $id = "$kind $name ON $table";
    push @keys, $id unless $key{$id};
    push @{ $key{$id} }, $column;
  }
  push @is, map { "$_ (" . join(', ', @{ $key{$_} }) . ')' } @keys;

  my (%index, @indexes);
  for my $row (@{ server_rows(qq{
    SELECT i.table_name, i.index_name, i.generated, i.uniqueness, c.column_name
    FROM user_indexes i
    JOIN user_ind_columns c ON c.index_name = i.index_name
    WHERE UPPER(i.table_name) $OWN
    ORDER BY i.table_name, i.index_name, c.column_position
  }) }) {
    my ($table, $name, $generated, $uniqueness, $column) = @$row;
    $name = '(system)' if $generated eq 'Y';
    my $id = ( $uniqueness eq 'UNIQUE' ? 'UNIQUE ' : '' ) . "INDEX $name ON $table";
    push @indexes, $id unless $index{$id};
    push @{ $index{$id} }, $column;
  }
  push @is, map { "$_ (" . join(', ', @{ $index{$_} }) . ')' } @indexes;

  push @is, map { "SEQUENCE $_->[0]" } @{ server_rows(qq{
    SELECT sequence_name FROM user_sequences
    WHERE UPPER(sequence_name) $OWN ORDER BY sequence_name
  }) };

  push @is, map { "TRIGGER $_->[0] ON $_->[1]" } @{ server_rows(qq{
    SELECT trigger_name, table_name FROM user_triggers
    WHERE UPPER(table_name) $OWN ORDER BY trigger_name
  }) };

  return \@is;
}

# PURGE keeps the tables out of the recycle bin, where they would still be
# something of this test. Whatever case the names have.
sub wipe {
  my $dbh = admin();
  $dbh->do(qq{DROP TABLE "$_->[0]" CASCADE CONSTRAINTS PURGE})
    for @{ server_rows(qq{
      SELECT table_name FROM user_tables WHERE UPPER(table_name) $OWN
    }) };
  $dbh->do(qq{DROP SEQUENCE "$_->[0]"})
    for @{ server_rows(qq{
      SELECT sequence_name FROM user_sequences WHERE UPPER(sequence_name) $OWN
    }) };
}

# run($dbh, sub { ... }) runs the code and says what went over the handle
# meanwhile:
#
#   value   what the code returned, undef if it died
#   error   what it died with
#   sent    every statement given to $dbh->do, in order -- that is how
#           DBIO::Deploy::Base::_execute_ddl sends its statements and how
#           section 4 sends the savepoint's; an introspection prepares its
#           queries and is not in here
#   ora     the ORA number of every error the handle raised, in order,
#           including those an eval inside the code swallowed
sub run {
  my ($dbh, $code) = @_;

  my (@sent, @ora);

  my $handler = $dbh->{HandleError};
  local $dbh->{HandleError} = sub {
    push @ora, ( $_[0] =~ /(ORA-\d+)/ )[0] // 'no ORA number';
    return $handler ? $handler->(@_) : 0;
  };
  local $dbh->{Callbacks} = {
    do => sub {
      # (the storage asks "select 1 from dual" to see whether it is connected)
      push @sent, $_[1] unless $_[1] =~ /\A\s*select 1 from dual\s*\z/i;
      return;
    },
  };

  my $value = eval { $code->() };
  my $error = defined $value ? undef : "$@";

  return { value => $value, error => $error, sent => \@sent, ora => \@ora };
}

sub first_words { [ map { join ' ', ( split ' ', $_ )[ 0 .. 2 ] } @{ $_[0] } ] }

# -------------------------------------------------------------- may it run
#
# install, diff and upgrade work on the whole schema of the user, not on the
# tables of this test. Beside somebody else's tables the answers below would
# be about those as well, and an upgrade that one day works would be entitled
# to drop them.

{
  my @foreign = map { $_->[0] } @{ server_rows(qq{
    SELECT table_name FROM user_tables
    WHERE table_name NOT LIKE 'BIN\$%' AND UPPER(table_name) NOT $OWN
    UNION ALL
    SELECT view_name FROM user_views
  }) };

  plan skip_all => "The schema of $user must hold no tables or views but "
    . "this test's own (k36_live_*); found: @foreign"
    if @foreign;
}

my $live = 1;   # past every skip_all: from here on there is something to drop

wipe();         # what a run that died before its END block may have left

is_deeply snapshot(), [], '(the schema holds nothing of this test to begin with)';

# The foreign key of Book -> Author: table, column and target in its name,
# shortened to Oracle's 30 characters (karr k42).
my $K36_FK = DBIO::Oracle::Identifier::shorten('fk_k36_live_book_author_id_k36_live_author');

# What install makes of V2 on an empty schema. Written out once, here; the
# sections below compare against it.
my @V2_INSTALLED = (
  'TABLE k36_live_account (id NUMBER NOT NULL)',
  'TABLE k36_live_author (id NUMBER NOT NULL, name VARCHAR2(100), email VARCHAR2(100))',
  'TABLE k36_live_book (id NUMBER NOT NULL, author_id NUMBER NOT NULL, title VARCHAR2(200))',
  'PRIMARY KEY (system) ON k36_live_account (id)',
  'PRIMARY KEY (system) ON k36_live_author (id)',
  'UNIQUE k36_live_author_email ON k36_live_author (email)',
  'PRIMARY KEY (system) ON k36_live_book (id)',
  "FOREIGN KEY $K36_FK ON k36_live_book (author_id)",
  'UNIQUE INDEX (system) ON k36_live_account (id)',
  'UNIQUE INDEX (system) ON k36_live_author (id)',
  'UNIQUE INDEX k36_live_author_email ON k36_live_author (email)',
  'UNIQUE INDEX (system) ON k36_live_book (id)',
  'SEQUENCE k36_live_author_id_seq',
  'TRIGGER k36_live_author_id_trg ON k36_live_author',
);

my @V1_INSTALLED = (
  'TABLE k36_live_author (id NUMBER NOT NULL, name VARCHAR2(100))',
  'PRIMARY KEY (system) ON k36_live_author (id)',
  'UNIQUE INDEX (system) ON k36_live_author (id)',
  'SEQUENCE k36_live_author_id_seq',
  'TRIGGER k36_live_author_id_trg ON k36_live_author',
);

# V1 with the first table of V2's install DDL beside it: where an install of
# V2 over V1 stops.
my @V1_AND_ACCOUNT = (
  'TABLE k36_live_account (id NUMBER NOT NULL)',
  'TABLE k36_live_author (id NUMBER NOT NULL, name VARCHAR2(100))',
  'PRIMARY KEY (system) ON k36_live_account (id)',
  'PRIMARY KEY (system) ON k36_live_author (id)',
  'UNIQUE INDEX (system) ON k36_live_account (id)',
  'UNIQUE INDEX (system) ON k36_live_author (id)',
  'SEQUENCE k36_live_author_id_seq',
  'TRIGGER k36_live_author_id_trg ON k36_live_author',
);

my $UNCOMMITTED
  = q{INSERT INTO "k36_live_author" ("id", "name") VALUES (1, 'uncommitted')};

sub rows_seen_elsewhere { server_value('SELECT COUNT(*) FROM "k36_live_author"') }

# in_callers_transaction($deploy, sub { ... }) is an application that has a
# row of its own open when it calls the deploy, and rolls back afterwards.
# Returns what the code returned, and how many rows another session saw right
# after the code and sees after the rollback.
sub in_callers_transaction {
  my ($deploy, $code) = @_;
  my $schema = $deploy->schema;

  my ($result, $seen_inside);

  eval {
    $schema->txn_do(sub {
      $schema->storage->dbh->do($UNCOMMITTED);
      $result      = $code->();
      $seen_inside = rows_seen_elsewhere();
      die "k36 the caller rolls back\n";
    });
  };
  die $@ unless $@ =~ /k36 the caller rolls back/;

  return ($result, $seen_inside, rows_seen_elsewhere());
}

# ===================================================================== 1
# install. It is the same call the test deploy of _build_target_model makes:
# _execute_ddl($dbh, _install_ddl).

# ------------------------------------------------- 1a. on an empty schema

{
  my $deploy = deploy_of('T::K36::V2');
  my $run    = run($deploy->_dbh, sub { $deploy->install });

  is $run->{error}, undef, 'IS: install on an empty schema lives';

  is_deeply first_words($run->{sent}), [
    'CREATE TABLE "k36_live_account"',
    'CREATE TABLE "k36_live_author"',
    'CREATE SEQUENCE "k36_live_author_id_seq"',
    'CREATE OR REPLACE',
    'CREATE TABLE "k36_live_book"',
    'ALTER TABLE "k36_live_book"',
  ], 'IS: ... with one statement per table, in the order of the source '
   . 'names, a sequence and its trigger for the auto-increment column (the '
   . 'unique constraint is part of the CREATE TABLE, karr k46), and the '
   . 'foreign key last (karr k42)';

  is_deeply snapshot(), \@V2_INSTALLED,
    'IS: it leaves the tables with their primary keys, the unique constraint, '
  . 'the sequence with the trigger that fills the auto-increment column from '
  . 'it, and the foreign key of the belongs_to -- under the lower-case names '
  . 'of the result classes (karr k42)';

  # The names are the ones the storage asks for (quoted, as the result class
  # spells them), so the schema that installed can read what it installed.
  my $schema = $deploy->schema;
  is eval { $schema->resultset('Author')->count }, 0,
    'IS: the schema that installed can query what it installed (karr k42)'
    or diag $@;

  # The sequence of an auto-increment column is found by the storage in the
  # BEFORE INSERT trigger (ALL_TRIGGERS). With RETURNING off, create() has
  # to read the key back through it: CURRVAL of that sequence.
  $schema->storage->_use_insert_returning(0);
  my $author = eval { $schema->resultset('Author')->create({ name => 'first' }) };
  is_deeply [ map { $author && $author->get_column($_) } qw(id name) ], [ 1, 'first' ],
    'IS: create() without RETURNING reads the generated key back: the '
  . 'storage found the sequence in the trigger the install wrote (karr k42)'
    or diag $@;
  my $seq = eval { $schema->storage->get_autoinc_seq($schema->source('Author'), 'id') };
  is ref $seq ? $$seq : $seq, uc($user) . '."k36_live_author_id_seq"',
    'IS: ... and it is the sequence install created'
    or diag $@;
  $schema->storage->_use_insert_returning(1);
  my $book = eval { $schema->resultset('Book')->create({ id => 1, author_id => 1, title => 'b' }) };
  ok $book, 'IS: a book of that author inserts' or diag $@;
  throws_ok {
    $schema->resultset('Book')->create({ id => 2, author_id => 99, title => 'orphan' });
  } qr/ORA-02291.*\Q$K36_FK\E/is,
    'IS: ... and one of an author that does not exist is refused: the foreign key is there (karr k42)';
  # The ORM deletes the parent first and its children after; the key has to be
  # ON DELETE CASCADE for that to get through (ORA-02292 without).
  lives_ok { $author->delete } 'IS: deleting an author that has books (cascade_delete) goes through (karr k42)'
    or diag $@;
  is server_value('SELECT COUNT(*) FROM "k36_live_book"'), 0,
    'IS: ... and its books are gone';
  admin()->do('DELETE FROM "k36_live_book"');
  admin()->do('DELETE FROM "k36_live_author"');

  # The names the Diff compares are the declared ones now: the introspected
  # tables and columns are those of the result classes, spelled the same, so
  # that a diff of the live schema against the declared one has no phantom
  # drop-and-create to make (the Diff compares tables, columns and indexes;
  # triggers, foreign keys and sequences it does not).
  {
    my $model = eval {
      DBIO::Oracle::Introspect->new(dbh => admin(), schema => uc $user)->model;
    } or diag $@;
    my %declared = map {
      my $src = $schema->source($_);
      ( $src->name => [ $src->columns ] );
    } $schema->sources;
    is_deeply [ sort keys %{ $model->{tables} // {} } ], [ sort keys %declared ],
      'IS: the introspected tables are the declared ones, spelled the same';
    is_deeply {
      map { $_ => [ map { $_->{column_name} } @{ $model->{columns}{$_} } ] }
        keys %{ $model->{columns} }
    }, \%declared, 'IS: ... and so are their columns, in order';
    my ($id) = grep { $_->{column_name} eq 'id' } @{ $model->{columns}{k36_live_author} };
    ok $id && $id->{is_auto_increment},
      'IS: the auto-increment column of the installed schema is introspected as such: '
    . 'the trigger names it :new."id" (karr k42)';
  }

# ------------------------------------------------------ 1b. a second time

  $run = run($deploy->_dbh, sub { $deploy->install });

  like $run->{error}, qr/ORA-00955/,
    'IS: a second install dies on the first table: the name is taken';

  is_deeply first_words($run->{sent}), [ 'CREATE TABLE "k36_live_account"' ],
    'IS: ... and stops there';

  is_deeply snapshot(), \@V2_INSTALLED, 'IS: ... the schema is as it was';
}

# ------------------------------------------- 1c. over an older schema (V1)

wipe();

{
  deploy_of('T::K36::V1')->install;

  is_deeply snapshot(), \@V1_INSTALLED, '(the older state: V1, installed)';

  my $deploy = deploy_of('T::K36::V2');
  my $run    = run($deploy->_dbh, sub { $deploy->install });

  like $run->{error}, qr/ORA-00955/,
    'IS: the install DDL of V2 over V1 dies on the table V1 has';

  is_deeply first_words($run->{sent}), [
    'CREATE TABLE "k36_live_account"',
    'CREATE TABLE "k36_live_author"',
  ], 'IS: ... the second statement; the rest was never sent';

  is_deeply snapshot(), \@V1_AND_ACCOUNT,
    'IS: what came before that table in the DDL was created and stays; the '
  . 'table itself did not get its new column, the one after it does not '
  . 'exist. This is what a test deploy has to make of every schema that is '
  . 'not empty';
}

# --------------------------- 1d. inside a transaction the caller has open
#
# The second install of 1b: one statement, and that one fails. It changes
# nothing in the schema and is the hardest case to expect a commit from.

wipe();

{
  my $deploy = deploy_of('T::K36::V2');
  $deploy->install;

  my ($run, $inside, $after) = in_callers_transaction($deploy, sub {
    run($deploy->_dbh, sub { $deploy->install });
  });

  like $run->{error}, qr/ORA-00955/, '(a second install, as in 1b)';

  is_deeply first_words($run->{sent}), [ 'CREATE TABLE "k36_live_account"' ],
    '(... one statement, which failed)';

  is $inside, 1,
    'IS: a row the caller had not committed is committed by that install: '
  . 'another session sees it';

  is $after, 1,
    'IS: ... and the caller\'s rollback does not take it back. A DDL '
  . 'statement commits what is open even when it fails on the name';
}

# ------------------------ 1e. a NOT NULL column with a default (karr k45)
#
# Oracle's column definition is "datatype [DEFAULT expr] [inline_constraint
# ...]". install wrote NOT NULL first, and the server refused the whole
# CREATE TABLE: ORA-03076 on this server. (The card had ORA-00907 from the
# reference; 23.26 does not say that.)

wipe();

{
  throws_ok {
    admin()->do(q{
      CREATE TABLE "k36_live_reversed" ("state" VARCHAR2(20) NOT NULL DEFAULT 'new')
    });
  } qr/ORA-03076/,
    'WHY: Oracle does not take NOT NULL in front of DEFAULT (ORA-03076, '
  . 'unexpected item DEFAULT in a column definition), so install has to '
  . 'write the default first';

  my $deploy = deploy_of('T::K36::Defaults');
  my $run    = run($deploy->_dbh, sub { $deploy->install });

  is $run->{error}, undef,
    'IS: install of a table whose NOT NULL columns have a default lives';

  is_deeply snapshot(), [
    'TABLE k36_live_defaulted (id NUMBER NOT NULL, state VARCHAR2(20) NOT NULL, '
  . 'hits NUMBER NOT NULL, twice NUMBER NOT NULL, note VARCHAR2(20), '
  . 'quip VARCHAR2(20), lead VARCHAR2(20), varnum VARCHAR2(20), ratio NUMBER)',
    'PRIMARY KEY (system) ON k36_live_defaulted (id)',
    'UNIQUE INDEX (system) ON k36_live_defaulted (id)',
  ], 'IS: ... and leaves the table, its columns NOT NULL as declared';

  # An insert that names none of the columns with a default, from the other
  # session and through nothing of this driver.
  my $row = eval {
    admin()->do('INSERT INTO "k36_live_defaulted" ("id") VALUES (1)');
    server_rows(q{SELECT "state", "hits", "twice", "note", "quip", "lead", "varnum",
                         TO_CHAR("ratio", 'FM0.0')
                  FROM "k36_live_defaulted" WHERE "id" = 1});
  };

  is_deeply $row, [ [ 'new', 0, 2, 'none', "it's", '007', '10', '0.5' ] ],
    'IS: a row inserted without those columns gets the defaults: the '
  . 'literal, the false one (0), the expression (1 + 1), that of the '
  . 'nullable column, a string with an apostrophe (karr k47), a string that '
  . 'looks like a number, a number in a character column and a fraction'
    or diag $@;

  # ... and the introspector reads every one of them back as it was declared,
  # so that the diff between the declared schema and this table has nothing
  # to say about a default (ADR 0009; karr k47).
  my $model = eval {
    DBIO::Oracle::Introspect->new(dbh => admin(), schema => uc $user)->model;
  } or diag $@;
  my %default = map { $_->{column_name} => $_->{default_value} }
    @{ $model->{columns}{k36_live_defaulted} // [] };

  is_deeply [ @default{qw(state hits note quip lead varnum ratio)} ],
    [ 'new', 0, 'none', "it's", '007', 10, 0.5 ],
    'IS: the introspector reads the defaults back as declared, the apostrophe '
  . 'undoubled (karr k47)';
  is ${ $default{twice} // \'(none)' }, '1 + 1', 'IS: ... and the expression as one';

  my %declared_default = ( quip => "it's", lead => '007', varnum => 10, ratio => 0.5 );
  my $declared = { %$model, columns => {
    k36_live_defaulted => [ map {
      my %c = %$_;
      $c{default_value} = $declared_default{ $c{column_name} }
        if exists $declared_default{ $c{column_name} };
      \%c;
    } @{ $model->{columns}{k36_live_defaulted} } ],
  } };
  is scalar @{ DBIO::Oracle::Diff->new(source => $model, target => $declared)->operations }, 0,
    'IS: the diff of that table against the defaults as declared is empty';
}

# ------------------------------ 1f. unique constraints (karr k46)
#
# add_unique_constraint used to leave no trace in the deployed table. Now the
# server holds the constraint under its name, and refuses a duplicate.

wipe();

{
  my $deploy = deploy_of('T::K36::Uniq');
  my $run    = run($deploy->_dbh, sub { $deploy->install });

  is $run->{error}, undef,
    'IS: install of a table with unique constraints lives (the primary key\'s '
  . 'columns and an earlier constraint\'s are not written a second time)';

  is_deeply snapshot(), [
    'TABLE k36_live_unique (id NUMBER NOT NULL, code VARCHAR2(10) NOT NULL, '
  . 'a NUMBER NOT NULL, b NUMBER NOT NULL)',
    'PRIMARY KEY (system) ON k36_live_unique (id)',
    'UNIQUE k36_live_u_code ON k36_live_unique (code)',
    'UNIQUE k36_live_u_pair ON k36_live_unique (a, b)',
    'UNIQUE INDEX (system) ON k36_live_unique (id)',
    'UNIQUE INDEX k36_live_u_code ON k36_live_unique (code)',
    'UNIQUE INDEX k36_live_u_pair ON k36_live_unique (a, b)',
  ], 'IS: ... the server holds the one-column and the two-column unique '
  . 'constraint under their names, in the declared column order';

  my $dbh = admin();
  $dbh->do(q{INSERT INTO "k36_live_unique" ("id", "code", "a", "b") VALUES (1, 'x', 1, 1)});
  for my $dup (
    [ 'a duplicate code',          q{(2, 'x', 2, 2)}, qr/ORA-00001.*k36_live_u_code/is ],
    [ 'a duplicate pair',          q{(3, 'y', 1, 1)}, qr/ORA-00001.*k36_live_u_pair/is ],
  ) {
    my ($what, $values, $re) = @$dup;
    throws_ok {
      $dbh->do("INSERT INTO \"k36_live_unique\" (\"id\", \"code\", \"a\", \"b\") VALUES $values");
    } $re, "IS: the server refuses $what";
  }
  lives_ok {
    $dbh->do(q{INSERT INTO "k36_live_unique" ("id", "code", "a", "b") VALUES (4, 'z', 1, 2)});
  } 'IS: ... and takes a row that repeats only one column of the pair';
}

# ===================================================================== 2
# diff and upgrade, through the temporary user. The desired state is built in
# DBIO_TMP_<pid>_<n> on connections of their own: the live handle gets no
# statement, the caller's transaction is none of their business, and the user
# is gone when the call returns.

sub temp_users {
  return [ map { $_->[0] } @{ server_rows(
    q{SELECT username FROM all_users WHERE username LIKE 'DBIO\_TMP\_%' ESCAPE '\'}
  ) } ];
}

# (a leftover of a run of this process that died: nobody else's)
admin()->do(qq{DROP USER "$_" CASCADE}) for grep { /\ADBIO_TMP_\Q$$\E_/ } @{ temp_users() };

is_deeply temp_users(), [], '(no temporary user on the server to begin with)';

# V1 with the column the desired state has: both sides have the table, so the
# diff is an ALTER and not a new table (karr k37).
my @V1B_INSTALLED = (
  'TABLE k36_live_author (id NUMBER NOT NULL, name VARCHAR2(100), email VARCHAR2(100))',
  'PRIMARY KEY (system) ON k36_live_author (id)',
  'UNIQUE INDEX (system) ON k36_live_author (id)',
  'SEQUENCE k36_live_author_id_seq',
  'TRIGGER k36_live_author_id_trg ON k36_live_author',
);

# 2a. a schema that is what is desired: nothing to do

wipe();
deploy_of('T::K36::V1B')->install;

{
  my $deploy = deploy_of('T::K36::V1B');
  my $run    = run($deploy->_dbh, sub { $deploy->diff });

  is $run->{error}, undef, 'IS: diff of an up-to-date schema lives';
  isa_ok $run->{value}, 'DBIO::Oracle::Diff', '... it returns a diff';
  ok !$run->{value}->has_changes, 'IS: ... and the diff is empty (no phantom difference)';

  is_deeply [ $run->{sent}, $run->{ora} ], [ [], [] ],
    'IS: no statement went over the live handle, and it raised no error';

  is_deeply temp_users(), [], 'IS: the temporary user is gone';
  is_deeply snapshot(), \@V1B_INSTALLED, 'IS: ... and the live schema is what it was';

  my $upgrade = run($deploy->_dbh, sub { [ $deploy->upgrade ] });
  is_deeply $upgrade->{value}, [], 'IS: upgrade of an up-to-date schema returns nothing ...';
  is_deeply $upgrade->{sent}, [], '... and sends nothing';
}

# 2b. a table that is not what is desired: the diff is an ALTER

wipe();
deploy_of('T::K36::V1')->install;

{
  my $deploy = deploy_of('T::K36::V1B');
  my $run    = run($deploy->_dbh, sub { $deploy->diff });

  is $run->{error}, undef, 'IS: diff over an older schema lives';
  ok $run->{value}->has_changes, 'IS: ... it has changes';
  like join("\n", $run->{value}->as_sql), qr/ALTER TABLE\s+"?k36_live_author"?\s+ADD\b.*\bemail\b/is,
    'IS: ... the missing column is added by an ALTER TABLE';

  is_deeply $run->{sent}, [], 'IS: no statement went over the live handle';
  is_deeply temp_users(), [], 'IS: the temporary user is gone';
  is_deeply snapshot(), \@V1_INSTALLED, 'IS: diff did not change the live schema';
}

# 2c. the caller's transaction: still open, still uncommitted

for my $method (qw(diff)) {
  wipe();
  deploy_of('T::K36::V1')->install;

  my $deploy = deploy_of('T::K36::V1B');

  my ($result, $inside, $after) = in_callers_transaction($deploy, sub {
    my $diff = eval { $deploy->$method };
    my $error = $@;
    # the caller's own session still has its row, uncommitted
    my ($own) = $deploy->schema->storage->dbh->selectrow_array(
      'SELECT COUNT(*) FROM "k36_live_author"'
    );
    return { diff => $diff, error => $error, own => $own };
  });

  is $result->{error}, '', "IS: $method inside a transaction of the caller lives";
  ok $result->{diff} && $result->{diff}->has_changes, '... and finds the difference';

  is $result->{own}, 1,
    'IS: ... the row the caller had open is still open in the caller\'s session';

  is_deeply [ $inside, $after ], [ 0, 0 ],
    "IS: $method does not commit a transaction the caller has open: "
  . 'another session does not see the row, and the caller\'s rollback '
  . 'takes it back (the old strategy committed it, 4b)';

  is_deeply temp_users(), [], 'IS: ... and no temporary user is left';
}

# ===================================================================== 3
# _build_target_model, called by itself: the desired state as a model, and
# nothing of the test deploy where the caller lives.

for my $state (
  [ 'an empty schema', undef,        []             ],
  [ 'an older schema', 'T::K36::V1', \@V1_INSTALLED ],
) {
  my ($name, $older, $holds) = @$state;

  wipe();
  deploy_of($older)->install if $older;

  my $deploy = deploy_of('T::K36::V1B');
  my $run    = run($deploy->_dbh, sub { $deploy->_build_target_model });

  is $run->{error}, undef, "IS: _build_target_model on $name lives";

  my @columns = map { $_->{column_name} }
    @{ ( $run->{value} // {} )->{columns}{k36_live_author} // [] };
  is_deeply [ sort @columns ], [ qw(email id name) ],
    'IS: ... the model is that of the desired state, whatever the live schema holds';

  is_deeply [ $run->{sent}, $run->{ora} ], [ [], [] ],
    'IS: ... the live handle was sent nothing: no savepoint, no test deploy';

  is_deeply snapshot(), $holds, "IS: ... $name is what it was";
  is_deeply temp_users(), [], 'IS: ... and the temporary user is gone';
}

# ===================================================================== 4
# The old strategy, replayed: the measured reason for ADR 0010.
# replay_test_deploy is what _build_target_model consisted of before the
# temporary user, statement for statement -- SAVEPOINT, _execute_ddl($dbh,
# _install_ddl), ROLLBACK TO SAVEPOINT in an eval -- with a savepoint name
# Oracle accepts and without the introspection between the deploy and the
# rollback, which only reads and is no part of what the card claims. Returns
# what the deploy died with, if it did, and the ORA numbers the handle
# raised.

my $SAVEPOINT = 'k36_live_deploy';

sub replay_test_deploy {
  my ($deploy) = @_;
  my $dbh = $deploy->_dbh;

  return run($dbh, sub {
    $dbh->do("SAVEPOINT $SAVEPOINT");

    my $error = eval {
      $deploy->_execute_ddl($dbh, $deploy->_install_ddl);
      '';
    } // "$@";

    eval { $dbh->do("ROLLBACK TO SAVEPOINT $SAVEPOINT"); };

    $error;
  });
}

# ------------------------------------------------- 4a. on an empty schema

wipe();

{
  my $deploy = deploy_of('T::K36::V2');
  my $run    = replay_test_deploy($deploy);

  is $run->{value}, '', '(the test deploy itself runs through)';

  is_deeply $run->{ora}, [ 'ORA-01086' ],
    'IS: ROLLBACK TO SAVEPOINT after the test deploy fails with ORA-01086: '
  . 'the savepoint is gone, and the eval around the rollback is all that '
  . 'keeps this from the caller. (Called like this, outside a transaction, '
  . 'it was gone before the deploy began -- see below; 4b is the same '
  . 'inside one)';

  is_deeply snapshot(), \@V2_INSTALLED,
    'IS: the test deploy stays in the live schema, all of it -- exactly '
  . 'what install leaves (1a). What was meant as a look at the desired '
  . 'state is the installation';
}

# The counter-proofs. ORA-01086 says little if a savepoint could not be
# rolled back to on this connection anyway.

wipe();

{
  deploy_of('T::K36::V1')->install;

  my $deploy = deploy_of('T::K36::V2');
  my $dbh    = $deploy->_dbh;

  # Outside a transaction -- AutoCommit, the way diff is called -- there is
  # no savepoint to lose in the first place.
  my $run = run($dbh, sub {
    $dbh->do("SAVEPOINT $SAVEPOINT");
    eval { $dbh->do("ROLLBACK TO SAVEPOINT $SAVEPOINT"); };
    1;
  });

  is_deeply $run->{ora}, [ 'ORA-01086' ],
    'IS: with AutoCommit on, the savepoint is gone before any DDL: every '
  . 'statement is committed by itself, SAVEPOINT too';

  # Inside one, and without DDL, it is what it should be.
  my ($ora, $inside, $after) = in_callers_transaction($deploy, sub {
    run($dbh, sub {
      $dbh->do("SAVEPOINT $SAVEPOINT");
      $dbh->do(q{INSERT INTO "k36_live_author" ("id", "name") VALUES (2, 'after')});
      $dbh->do("ROLLBACK TO SAVEPOINT $SAVEPOINT");
      1;
    })->{ora};
  });

  is_deeply $ora, [],
    'in a transaction, with no DDL after it, the same savepoint can be '
  . 'rolled back to';

  is_deeply [ $inside, $after ], [ 0, 0 ],
    '... and the transaction around it is still the caller\'s to roll back';
}

# ----------------- 4b. on an older schema, in a transaction of the caller
#
# The row the caller has open is the data this costs: after a rollback it is
# in the table, committed by a call that was to compare two schemas.

wipe();

{
  deploy_of('T::K36::V1')->install;

  my $deploy = deploy_of('T::K36::V2');

  my ($run, $inside, $after) = in_callers_transaction($deploy, sub {
    replay_test_deploy($deploy);
  });

  like $run->{value}, qr/ORA-00955/,
    'IS: on an older schema the test deploy dies on the first table that '
  . 'exists (1c)';

  is_deeply $run->{ora}, [ 'ORA-00955', 'ORA-01086' ],
    'IS: ... and the rollback to the savepoint fails behind it, unseen';

  is $inside, 1,
    'IS: the caller\'s uncommitted row is committed by the test deploy: '
  . 'another session sees it';

  is $after, 1,
    'IS: ... and it stays when the caller rolls back';

  is_deeply snapshot(), \@V1_AND_ACCOUNT,
    'IS: ... as does the table the test deploy got to before it died';
}

# ===================================================================== 5
# upgrade end to end, and the failure path. (The tables of V2 that V1 lacks
# are t/55, karr k37: what is upgraded here is a column of a table both have.)
#
# The table and its columns are spelled in upper case here. (Diff::Column wrote
# the names bare, which missed a lower-case table of the install, karr k42;
# karr k61 quotes them, t/83-diff-quoting-live.t holds the lower-case case.)

{
  package T::K36::U1::Up;
  use base 'DBIO::Core';
  __PACKAGE__->table('K36_LIVE_UP');
  __PACKAGE__->add_columns(
    ID   => { data_type => 'integer' },
    NAME => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('ID');
}

{
  package T::K36::U1B::Up;
  use base 'DBIO::Core';
  __PACKAGE__->table('K36_LIVE_UP');
  __PACKAGE__->add_columns(
    ID    => { data_type => 'integer' },
    NAME  => { data_type => 'varchar', size => 100, is_nullable => 1 },
    EMAIL => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('ID');
}

for my $v (qw(U1 U1B)) {
  no strict 'refs';
  @{"T::K36::${v}::ISA"} = ('DBIO::Schema');
  "T::K36::$v"->load_components('Oracle');
  "T::K36::$v"->register_class(Up => "T::K36::${v}::Up");
}

my @UP_OLD = (
  'TABLE K36_LIVE_UP (ID NUMBER NOT NULL, NAME VARCHAR2(100))',
  'PRIMARY KEY (system) ON K36_LIVE_UP (ID)',
  'UNIQUE INDEX (system) ON K36_LIVE_UP (ID)',
);
my @UP_NEW = (
  'TABLE K36_LIVE_UP (ID NUMBER NOT NULL, NAME VARCHAR2(100), EMAIL VARCHAR2(100))',
  @UP_OLD[1, 2],
);

wipe();
deploy_of('T::K36::U1')->install;

is_deeply snapshot(), \@UP_OLD, '(the older state of the upgrade is installed)';

{
  my $deploy = deploy_of('T::K36::U1B');
  my $first  = eval { $deploy->upgrade };
  my $error  = $@;

  is $error, '', 'IS: upgrade over an older schema lives';
  isa_ok $first, 'DBIO::Oracle::Diff', '... and returns the diff it applied';

  is_deeply snapshot(), \@UP_NEW,
    'IS: ... the missing column was added: the schema is the desired state';
  is_deeply temp_users(), [], 'IS: ... and no temporary user is left';

  my $second = eval { $deploy->upgrade };
  is $@, '', 'IS: a second upgrade lives';
  is $second, undef, '... and finds nothing left to do';
  is_deeply snapshot(), \@UP_NEW, '... and the schema is as it was';
}

# diff on an empty schema: the desired state is built, compared, and the live
# schema stays empty (what the diff holds for the new table is t/55, karr k37).

wipe();

{
  my $deploy = deploy_of('T::K36::V1B');
  my $diff   = eval { $deploy->diff };

  is $@, '', 'IS: diff on an empty schema lives';
  isa_ok $diff, 'DBIO::Oracle::Diff', '... it returns a diff';
  is_deeply snapshot(), [], 'IS: ... and the test deploy behind it leaves nothing in the schema';
  is_deeply temp_users(), [], 'IS: ... nor a temporary user on the server';
}

# The failure path: the install DDL dies in the temp user (a default that
# calls a function that is not there). The error is the deploy's, and the
# user is dropped all the same.

{
  package T::K36::Broken::Thing;
  use base 'DBIO::Core';
  __PACKAGE__->table('k36_live_broken');
  __PACKAGE__->add_columns(
    id  => { data_type => 'integer' },
    bad => { data_type => 'integer', is_nullable => 1, default_value => \'k36_no_such_function(1)' },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K36::Broken;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
  __PACKAGE__->register_class(Thing => 'T::K36::Broken::Thing');
}

wipe();

{
  my $deploy = deploy_of('T::K36::Broken');
  my $run    = run($deploy->_dbh, sub { $deploy->diff });

  like $run->{error}, qr/ORA-\d{5}/,
    'IS: a test deploy that dies on the server dies the diff, with the ORA error';
  is_deeply temp_users(), [],
    'IS: ... and the temporary user is dropped all the same';
  is_deeply snapshot(), [], 'IS: ... and the live schema is untouched';
  is_deeply $run->{sent}, [], 'IS: ... the live handle was sent nothing';
}

# ================================================================ the end

wipe();

is_deeply snapshot(), [], 'nothing of this test is left in the schema';

is_deeply temp_users(), [], '... no temporary user on the server';

is_deeply
  server_rows(qq{SELECT original_name FROM user_recyclebin WHERE UPPER(original_name) $OWN}),
  [],
  '... and nothing in its recycle bin';

is_deeply \@warnings, [],
  'no warning on the way, beside core\'s notice that this DDL is not atomic';

done_testing;

# Again on a new connection: for a run that died on the way.
END {
  if ($live) {
    local $?;
    undef $admin;
    eval { wipe(); 1 }
      or diag "Could not drop the k36_live_* objects: $@";
    eval { admin()->do(qq{DROP USER "$_" CASCADE}) for grep { /\ADBIO_TMP_\Q$$\E_/ } @{ temp_users() }; 1 }
      or diag "Could not drop a temporary user of this run: $@";
  }
}
