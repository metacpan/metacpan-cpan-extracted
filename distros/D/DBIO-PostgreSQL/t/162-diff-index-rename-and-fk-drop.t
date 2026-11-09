use strict;
use warnings;

use Test::More;

use DBIO::PostgreSQL::Diff::Index;

# karr k139 / k140, the two cases the review of the first fix measured:
#
# 1. The database has the key as a unique index under another name than the
#    target's constraint (parent_code_uidx against parent_code_key). A second
#    index leaves the foreign key on the old one, whose DROP INDEX then fails.
#    The index is renamed and the constraint put on it.
# 2. A constraint that goes, with foreign keys of other tables on it, is
#    refused only while a key stays on it; a key the target drops or points
#    elsewhere is gone before the constraint is (the drops of the keys come
#    ahead of the drops of the indexes).
#
# These are the claims without a server; t/163-diff-index-rename-and-fk-drop-live.t
# has each measured.

my $TABLES = {
  'public.t' => { schema_name => 'public', table_name => 't', kind => 'r' },
  'public.o' => { schema_name => 'public', table_name => 'o', kind => 'r' },
};

sub entry {
  my ($name, $columns, %more) = @_;
  my $list = join ', ', map { $_ // '' } @$columns;
  return ($name => {
    index_name => $name, access_method => 'btree', is_unique => 1, is_primary => 0, is_valid => 1,
    definition => "CREATE UNIQUE INDEX $name ON public.t USING btree ($list)",
    predicate => undef, expressions => undef,
    columns => $columns, include_columns => [], storage_params => {},
    opclasses => {}, sort_options => {},
    constraint_name => undef, constraint_type => undef, referenced_by => [],
    %more,
  });
}

sub pk     { my ($name, @cols) = @_; entry($name, \@cols, is_primary => 1, constraint_name => $name, constraint_type => 'p') }
sub unique { my ($name, @cols) = @_; entry($name, \@cols, constraint_name => $name, constraint_type => 'u') }
sub bare   { my ($name, @cols) = @_; entry($name, \@cols) }

sub model { return { 'public.t' => { map { @$_ } @_ } } }

sub ops {
  my ($source, $target, $src_tables, $tgt_tables, @fk) = @_;
  return DBIO::PostgreSQL::Diff::Index->diff($source, $target, $src_tables // $TABLES, $tgt_tables // $TABLES, @fk);
}

sub sql { return [ map { $_->as_sql } @_ ] }

sub refusal {
  my ($label, @args) = @_;
  my @ops = eval { ops(@args) };
  my $error = $@;
  is(scalar(@ops), 0, "$label: no operation is built") or diag join "\n", map { $_->as_sql } @ops;
  like($error, qr/\Arefusing to diff: /, "$label: it is refused");
  return $error;
}

# ---------------------------------------------------------------------------
# 1. The index under another name
# ---------------------------------------------------------------------------
{
  my @ops = ops(model([ bare('parent_code_uidx', 'code') ]), model([ unique('parent_code_key', 'code') ]));
  is_deeply(sql(@ops), [
      'ALTER INDEX public.parent_code_uidx RENAME TO parent_code_key;',
      'ALTER TABLE public.t ADD CONSTRAINT parent_code_key UNIQUE USING INDEX parent_code_key;',
    ], 'a unique index under another name than the UNIQUE constraint of the target: renamed, the constraint put on it');
  is_deeply([ map { $_->summary } @ops ], [
      '  ~index: parent_code_uidx -> parent_code_key (on public.t)',
      '  +constraint: parent_code_key (on public.t)',
    ], '... the summary says both');
  unlike(join('', @{ sql(@ops) }), qr/CREATE UNIQUE INDEX|DROP INDEX/, '... no second index, nothing dropped');

  @ops = ops(model([ bare('t_id_uidx', 'id') ]), model([ pk('t_pkey', 'id') ]));
  is_deeply(sql(@ops), [
      'ALTER INDEX public.t_id_uidx RENAME TO t_pkey;',
      'ALTER TABLE public.t ADD CONSTRAINT t_pkey PRIMARY KEY USING INDEX t_pkey;',
    ], 'the same for a PRIMARY KEY');

  # a composite key: the columns are in the definition, in key order
  @ops = ops(model([ bare('t_ab_uidx', 'a', 'b') ]), model([ unique('t_a_b_key', 'a', 'b') ]));
  is_deeply(sql(@ops), [
      'ALTER INDEX public.t_ab_uidx RENAME TO t_a_b_key;',
      'ALTER TABLE public.t ADD CONSTRAINT t_a_b_key UNIQUE USING INDEX t_a_b_key;',
    ], 'a composite key is found by its definition');

  # a quoted name in the definition
  @ops = ops(model([ entry('Code Uidx', ['code'], definition => 'CREATE UNIQUE INDEX "Code Uidx" ON public.t USING btree (code)') ]),
    model([ unique('t_code_key', 'code') ]));
  is_deeply(sql(@ops), [
      'ALTER INDEX public."Code Uidx" RENAME TO t_code_key;',
      'ALTER TABLE public.t ADD CONSTRAINT t_code_key UNIQUE USING INDEX t_code_key;',
    ], 'an index whose name needs quotes is found and renamed');

  # not the same index: another key, another table, one the target keeps, one with a constraint
  @ops = ops(model([ bare('t_x_uidx', 'x') ]), model([ unique('t_code_key', 'code') ]));
  is_deeply(sql(@ops), [
      'ALTER TABLE public.t ADD CONSTRAINT t_code_key UNIQUE (code);',
      'DROP INDEX public.t_x_uidx;',
    ], 'an index over other columns is not the one: the constraint is created, the index dropped');

  @ops = ops(model([ bare('t_code_uidx', 'code') ]), model([ bare('t_code_uidx', 'code'), unique('t_code_key', 'code') ]));
  is_deeply(sql(@ops), ['ALTER TABLE public.t ADD CONSTRAINT t_code_key UNIQUE (code);'],
    'an index the target keeps under its name is not taken');

  @ops = ops(model([ unique('t_code_old', 'code') ]), model([ unique('t_code_key', 'code') ]));
  is_deeply(sql(@ops), [ 'ALTER TABLE public.t RENAME CONSTRAINT t_code_old TO t_code_key;' ],
    'the constraint of the same definition under another name is renamed, with its index (karr k139)');

  @ops = ops({ 'public.o' => { bare('t_code_uidx', 'code') } }, model([ unique('t_code_key', 'code') ]));
  unlike(join('', @{ sql(@ops) }), qr/RENAME/, 'an index of another table is not taken');

  # two like indexes, one constraint: one is renamed, the other dropped
  @ops = ops(model([ bare('t_code_a', 'code'), bare('t_code_b', 'code') ]), model([ unique('t_code_key', 'code') ]));
  is_deeply(sql(@ops), [
      'ALTER INDEX public.t_code_a RENAME TO t_code_key;',
      'ALTER TABLE public.t ADD CONSTRAINT t_code_key UNIQUE USING INDEX t_code_key;',
      'DROP INDEX public.t_code_b;',
    ], 'each index serves one constraint, the other is dropped');

  # a plain index under another name stays what it was: created and dropped
  @ops = ops(model([ bare('t_code_old', 'code') ]), model([ bare('t_code_new', 'code') ]));
  is_deeply(sql(@ops), [
      'CREATE UNIQUE INDEX t_code_new ON public.t USING btree (code);',
      'DROP INDEX public.t_code_old;',
    ], 'a plain index under another name is created and dropped, as before');

  # the refusals of USING INDEX hold for the renamed one
  my $parts = { 'public.t' => { %{ $TABLES->{'public.t'} }, kind => 'p' } };
  my $error = refusal('partitioned', model([ bare('t_code_uidx', 'code') ]), model([ unique('t_code_key', 'code') ]), $parts);
  like($error, qr/partitioned/, '... a partitioned table says why');
  unlike($error, qr/USING INDEX would rename the index/, '... and not that the index would be renamed');

  $error = refusal('invalid', model([ entry('t_code_uidx', ['code'], is_valid => 0) ]), model([ unique('t_code_key', 'code') ]));
  like($error, qr/not valid/, '... an invalid index says why');

  $error = refusal('second primary key', model([ pk('t_old_pkey', 'x'), bare('t_id_uidx', 'id') ]), model([ pk('t_pkey', 'id') ]));
  like($error, qr/multiple primary keys/, '... a primary key of another name on the table is still refused');
}

# ---------------------------------------------------------------------------
# 2. A constraint that goes with foreign keys on it
# ---------------------------------------------------------------------------
{
  my @by = ({ schema_name => 'public', table_name => 'o', constraint_name => 'o_t_fkey' });
  my %with_fk = (referenced_by => \@by);
  my $source = sub { model([ entry('t_code_key', ['code'], constraint_name => 't_code_key', constraint_type => 'u', %with_fk) ]) };
  my $fk = sub { { constraint_name => 'o_t_fkey', local_columns => ['t_code'], remote_schema => 'public', remote_table => 't', remote_columns => [@_] } };
  my $src_fks = { 'public.o' => [ $fk->('code') ] };

  # the target drops the key (belongs_to and UNIQUE removed)
  my @ops = ops($source->(), {}, $TABLES, $TABLES, $src_fks, {});
  is_deeply(sql(@ops), ['ALTER TABLE public.t DROP CONSTRAINT t_code_key;'],
    'a constraint a foreign key points at goes when the target has no such key');

  # the key moves to another column
  @ops = ops($source->(), {}, $TABLES, $TABLES, $src_fks, { 'public.o' => [ $fk->('id') ] });
  is_deeply(sql(@ops), ['ALTER TABLE public.t DROP CONSTRAINT t_code_key;'],
    '... also when the key is moved to other columns');

  # the key stays on the constraint
  my $error = refusal('key stays', $source->(), {}, $TABLES, $TABLES, $src_fks, { 'public.o' => [ $fk->('code') ] });
  like($error, qr/^  +ALTER TABLE public\.o DROP CONSTRAINT o_t_fkey;$/m, 'a key that stays is refused, named');

  # a key that stays with other actions still points at it
  my $changed = $fk->('code'); $changed->{on_delete} = 'CASCADE';
  refusal('key stays changed', $source->(), {}, $TABLES, $TABLES, $src_fks, { 'public.o' => [ $changed ] });

  # no foreign keys in the target model: nothing drops them
  refusal('no section', $source->(), {}, $TABLES, $TABLES, $src_fks, undef);
  refusal('no sections', $source->(), {}, $TABLES, $TABLES);

  # the table of the key is dropped by the target: it goes after the index
  my $only_t = { 'public.t' => $TABLES->{'public.t'} };
  refusal('table of the key dropped', $source->(), {}, $TABLES, $only_t, $src_fks, {});

  # the key is not in the source model (the copy at a partition)
  refusal('key unknown', $source->(), {}, $TABLES, $TABLES, {}, {});

  # a constraint that is dropped and added again goes ahead of every drop of a key
  my $target = model([ unique('t_code_key', 'code', 'x') ]);
  $error = refusal('replaced, key goes', $source->(), $target, $TABLES, $TABLES, $src_fks, {});
  like($error, qr/^  +ALTER TABLE public\.o DROP CONSTRAINT o_t_fkey;$/m, 'a changed constraint is refused while a key is on it, though the target drops the key');
  refusal('replaced, key stays', $source->(), $target, $TABLES, $TABLES, $src_fks, $src_fks);

  # a foreign key that is gone does not hide one that is not
  my @two = (@by, { schema_name => 'public', table_name => 'o', constraint_name => 'o_other_fkey' });
  my $src2 = { 'public.o' => [ $fk->('code'), { %{ $fk->('code') }, constraint_name => 'o_other_fkey' } ] };
  my $tgt2 = { 'public.o' => [ { %{ $fk->('code') }, constraint_name => 'o_other_fkey' } ] };
  $error = refusal('one of two stays',
    model([ entry('t_code_key', ['code'], constraint_name => 't_code_key', constraint_type => 'u', referenced_by => \@two) ]),
    {}, $TABLES, $TABLES, $src2, $tgt2);
  unlike($error, qr/DROP CONSTRAINT o_t_fkey;/, 'only the key that stays is named');
  like($error, qr/DROP CONSTRAINT o_other_fkey;/, '... the other is');

  # a plain unique index nothing stands on is no matter
  @ops = ops(model([ bare('t_code_uidx', 'code') ]), {});
  is_deeply(sql(@ops), ['DROP INDEX public.t_code_uidx;'], 'an index without a constraint is dropped as before');
}

# ---------------------------------------------------------------------------
# 3. The second review: the name is taken, and what is refused ahead of the apply
# ---------------------------------------------------------------------------
{
  # The nonunique index t_code_key holds the name of the target's constraint:
  # it goes first, then the unique index under another name is renamed and
  # taken. Before, t_code_uidx was dropped at the end, under the key.
  my @ops = ops(
    model([ bare('t_code_uidx', 'code') ],
      [ entry('t_code_key', ['id', 'code'], is_unique => 0, definition => 'CREATE INDEX t_code_key ON public.t USING btree (id, code)') ]),
    model([ unique('t_code_key', 'code') ]));
  is_deeply(sql(@ops), [
      'DROP INDEX public.t_code_key;',
      'ALTER INDEX public.t_code_uidx RENAME TO t_code_key;',
      'ALTER TABLE public.t ADD CONSTRAINT t_code_key UNIQUE USING INDEX t_code_key;',
    ], 'the index that holds the name goes first, the unique index under another name takes it');

  # A primary key of the same definition under another name is renamed
  @ops = ops(model([ pk('t_id_pk', 'id') ]), model([ pk('t_pkey', 'id') ]));
  is_deeply(sql(@ops), [ 'ALTER TABLE public.t RENAME CONSTRAINT t_id_pk TO t_pkey;' ],
    'a primary key of the same definition under another name is renamed');
  like(join('', map { $_->summary } @ops), qr/~constraint: t_id_pk -> t_pkey \(on public\.t\)/, '... the summary says it');

  # An index the run drops that the key the target creates would be bound to:
  # the fillfactor makes it another index than the target's, so it is no
  # rename, and the server binds the new key to the older of the two.
  my $old = [ entry('t_code_uidx', ['code'], storage_params => { fillfactor => 70 },
    definition => 'CREATE UNIQUE INDEX t_code_uidx ON public.t USING btree (code) WITH (fillfactor=70)') ];
  my $key = { constraint_name => 'o_t_code_fkey', remote_schema => 'public', remote_table => 't',
    remote_columns => ['code'], local_columns => ['t_code'] };
  my @args = (model($old), model([ unique('t_code_key', 'code') ]), $TABLES, $TABLES);
  my $error = do { local $@; eval { DBIO::PostgreSQL::Diff::Index->diff(@args, {}, { 'public.o' => [ $key ] }) }; $@ };
  like($error, qr/\Arefusing to diff: index t_code_uidx on public\.t is dropped by this run/, 'a new key onto the columns of a dropped index is refused');
  like($error, qr/o_t_code_fkey on public\.o/, '... naming the key');
  like($error, qr/DROP INDEX public\.t_code_uidx;/, '... and the statement that settles it');

  # the key is there already and unchanged: bound to the index, which cannot go
  my $bound = [ entry('t_code_uidx', ['code'], referenced_by => [ { schema_name => 'public', table_name => 'o', constraint_name => 'o_t_code_fkey' } ],
    storage_params => { fillfactor => 70 }, definition => 'CREATE UNIQUE INDEX t_code_uidx ON public.t USING btree (code) WITH (fillfactor=70)') ];
  $error = do { local $@; eval { DBIO::PostgreSQL::Diff::Index->diff(model($bound), model([ unique('t_code_key', 'code') ]), $TABLES, $TABLES,
    { 'public.o' => [ $key ] }, { 'public.o' => [ $key ] }) }; $@ };
  like($error, qr/index t_code_uidx on public\.t is dropped by this run/, 'a key that stands on a dropped index is refused');
  like($error, qr/ALTER TABLE public\.o DROP CONSTRAINT o_t_code_fkey;/, '... naming the key to drop');

  # no foreign key sections: nothing to bind
  @ops = ops(model($old), model([ unique('t_code_key', 'code') ]));
  is_deeply(sql(@ops), [ 'ALTER TABLE public.t ADD CONSTRAINT t_code_key UNIQUE (code);', 'DROP INDEX public.t_code_uidx;' ],
    'without foreign key sections the index is dropped as before');
}

done_testing;
