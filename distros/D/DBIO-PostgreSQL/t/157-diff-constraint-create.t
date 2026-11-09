use strict;
use warnings;

use Test::More;

use DBIO::PostgreSQL::Diff::Index;

# karr k139: the diff creates the PRIMARY KEY and UNIQUE constraint of a table,
# not the bare index behind it. pg_get_indexdef writes the same text for the
# index of a constraint and for a unique index without one, so a diff that
# creates "the index from its definition" leaves the table without the
# constraint, and the comparison by definition never sees it. These are the
# claims without a server; t/158-diff-constraint-live.t has each measured.

my $TABLES = { 'public.t' => { schema_name => 'public', table_name => 't', kind => 'r' } };

# An index entry as the introspection gives it for a unique btree index on
# public.t; %more overrides.
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
  my ($source, $target, $src_tables) = @_;
  return DBIO::PostgreSQL::Diff::Index->diff($source, $target, $src_tables // $TABLES, $TABLES);
}

sub sql { return [ map { $_->as_sql } @_ ] }

# diff dies with the refusal; returns its message.
sub refusal {
  my ($label, @args) = @_;
  my @ops = eval { ops(@args) };
  my $error = $@;
  is(scalar(@ops), 0, "$label: no operation is built") or diag join "\n", map { $_->as_sql } @ops;
  like($error, qr/\Arefusing to diff: /, "$label: it is refused");
  return $error;
}

# ---------------------------------------------------------------------------
# 1. The table is new, or has no such index yet: the constraint is created
# ---------------------------------------------------------------------------
{
  my @ops = ops({}, model([ pk('t_pkey', 'id') ], [ unique('t_a_key', 'a', 'b') ]));
  is_deeply(sql(@ops), [
      'ALTER TABLE public.t ADD CONSTRAINT t_a_key UNIQUE (a, b);',
      'ALTER TABLE public.t ADD CONSTRAINT t_pkey PRIMARY KEY (id);',
    ], 'a PRIMARY KEY and a UNIQUE constraint of the target are created as constraints, not as indexes');
  is_deeply([ map { $_->summary } @ops ], [
      '  +constraint: t_a_key (on public.t)',
      '  +constraint: t_pkey (on public.t)',
    ], '... and the summary says constraint');
  unlike(join('', @{ sql(@ops) }), qr/CREATE UNIQUE INDEX/, '... no CREATE UNIQUE INDEX for either');

  @ops = ops({}, model([ bare('t_a_uidx', 'a') ]));
  is_deeply(sql(@ops), ['CREATE UNIQUE INDEX t_a_uidx ON public.t USING btree (a);'],
    'a unique index no constraint stands on stays an index');
  is($ops[0]->summary, '  +index: t_a_uidx (on public.t)', '... and the summary says index');

  # The key position is kept: PRIMARY KEY (b, a) is not PRIMARY KEY (a, b).
  @ops = ops({}, model([ pk('t_pkey', 'b', 'a') ]));
  is_deeply(sql(@ops), ['ALTER TABLE public.t ADD CONSTRAINT t_pkey PRIMARY KEY (b, a);'],
    'the columns of a primary key are written in the order of the key');

  # Names are written by the server's rule, columns too.
  @ops = ops({}, model([ unique('Mixed Key', 'Col A', 'select') ]));
  is_deeply(sql(@ops), ['ALTER TABLE public.t ADD CONSTRAINT "Mixed Key" UNIQUE ("Col A", "select");'],
    'names are quoted as identifiers');
}

# INCLUDE, storage parameters and NULLS NOT DISTINCT are written (measured on PostgreSQL 18.6)
{
  my @ops = ops({}, model(
    [ entry('t_a_key', ['a'], constraint_name => 't_a_key', constraint_type => 'u',
        include_columns => ['b'], storage_params => { fillfactor => 70 },
        definition => 'CREATE UNIQUE INDEX t_a_key ON public.t USING btree (a) INCLUDE (b) WITH (fillfactor=70)') ],
    [ entry('t_c_key', ['c'], constraint_name => 't_c_key', constraint_type => 'u',
        definition => 'CREATE UNIQUE INDEX t_c_key ON public.t USING btree (c) NULLS NOT DISTINCT') ],
  ));
  is_deeply(sql(@ops), [
      'ALTER TABLE public.t ADD CONSTRAINT t_a_key UNIQUE (a) INCLUDE (b) WITH (fillfactor = 70);',
      'ALTER TABLE public.t ADD CONSTRAINT t_c_key UNIQUE NULLS NOT DISTINCT (c);',
    ], 'INCLUDE, WITH and NULLS NOT DISTINCT of the index are the constraint\'s');
}

# What a constraint cannot say is refused, not written as an index
{
  my $error = refusal('exclusion constraint', {}, model([
    entry('t_x_excl', ['x'], is_unique => 0, constraint_name => 't_x_excl', constraint_type => 'x',
      definition => 'CREATE INDEX t_x_excl ON public.t USING gist (x)') ]));
  like($error, qr/index t_x_excl on public\.t is the index of the EXCLUDE constraint t_x_excl/, 'EXCLUDE: names index and constraint');
  like($error, qr/^  +ALTER TABLE public\.t ADD CONSTRAINT t_x_excl EXCLUDE \(\.\.\.\);$/m, '... and the clause it cannot write');
  like($error, qr/No statement\s+was generated/, '... and says nothing was written');

  $error = refusal('descending key', {}, model([
    entry('t_a_key', ['a'], constraint_name => 't_a_key', constraint_type => 'u', sort_options => { a => 'DESC' },
      definition => 'CREATE UNIQUE INDEX t_a_key ON public.t USING btree (a DESC)') ]));
  like($error, qr/sort order/, 'a sort order a constraint cannot have: refused, and says so');

  $error = refusal('operator class', {}, model([
    entry('t_a_key', ['a'], constraint_name => 't_a_key', constraint_type => 'u', opclasses => { a => 'text_pattern_ops' },
      definition => 'CREATE UNIQUE INDEX t_a_key ON public.t USING btree (a text_pattern_ops)') ]));
  like($error, qr/operator class/, 'an operator class a constraint cannot have: refused, and says so');

  $error = refusal('no columns', {}, model([
    entry('t_a_key', [undef], constraint_name => 't_a_key', constraint_type => 'u') ]));
  like($error, qr/expression|columns/, 'a constraint without columns to name: refused');
}

# ---------------------------------------------------------------------------
# 2. The database holds the key as an index only: ADD CONSTRAINT ... USING INDEX
# ---------------------------------------------------------------------------
{
  my @ops = ops(
    model([ bare('t_pkey', 'id') ], [ bare('t_a_key', 'a') ]),
    model([ pk('t_pkey', 'id') ],   [ unique('t_a_key', 'a') ]),
  );
  is_deeply(sql(@ops), [
      'ALTER TABLE public.t ADD CONSTRAINT t_a_key UNIQUE USING INDEX t_a_key;',
      'ALTER TABLE public.t ADD CONSTRAINT t_pkey PRIMARY KEY USING INDEX t_pkey;',
    ], 'the same index without its constraint becomes the constraint, using the index (no second index, no drop)');
  is_deeply([ map { $_->action } @ops ], [ 'create', 'create' ], '... as creates');
  is_deeply([ map { $_->summary } @ops ], [
      '  +constraint: t_a_key (on public.t)',
      '  +constraint: t_pkey (on public.t)',
    ], '... and the summary names them');

  # And once it is there, there is nothing to do.
  @ops = ops(model([ pk('t_pkey', 'id') ], [ unique('t_a_key', 'a') ]), model([ pk('t_pkey', 'id') ], [ unique('t_a_key', 'a') ]));
  is(scalar @ops, 0, 'the second diff is empty');

  # INCLUDE and NULLS NOT DISTINCT are kept by USING INDEX (measured)
  my %inc = (include_columns => ['b'],
    definition => 'CREATE UNIQUE INDEX t_a_key ON public.t USING btree (a) INCLUDE (b)');
  @ops = ops(model([ entry('t_a_key', ['a'], %inc) ]),
             model([ entry('t_a_key', ['a'], %inc, constraint_name => 't_a_key', constraint_type => 'u') ]));
  is_deeply(sql(@ops), ['ALTER TABLE public.t ADD CONSTRAINT t_a_key UNIQUE USING INDEX t_a_key;'],
    'an index with INCLUDE columns is taken as it is');
}

# A source index the server would refuse for USING INDEX is refused here, before any statement
{
  my %cases = (
    'partial index' => [ { predicate => '(a > 0)', definition => 'CREATE UNIQUE INDEX t_a_key ON public.t USING btree (a) WHERE (a > 0)' }, qr/predicate/ ],
    'expression'    => [ { columns => [undef], expressions => '(a + 1)', definition => 'CREATE UNIQUE INDEX t_a_key ON public.t USING btree (((a + 1)))' }, qr/expression/ ],
    'descending'    => [ { sort_options => { a => 'DESC' }, definition => 'CREATE UNIQUE INDEX t_a_key ON public.t USING btree (a DESC)' }, qr/sort order/ ],
    'not unique'    => [ { is_unique => 0, definition => 'CREATE INDEX t_a_key ON public.t USING btree (a)' }, qr/not unique/ ],
    'hash'          => [ { access_method => 'hash', is_unique => 0, definition => 'CREATE INDEX t_a_key ON public.t USING hash (a)' }, qr/hash/ ],
    'invalid'       => [ { is_valid => 0 }, qr/not valid/ ],
  );
  for my $label (sort keys %cases) {
    my ($change, $why) = @{ $cases{$label} };
    # the target's definition is the one of the source: only the constraint is missing
    my %have = entry('t_a_key', ['a'], %$change);
    my %want = entry('t_a_key', ['a'], %$change, constraint_name => 't_a_key', constraint_type => 'u');
    my $error = refusal("USING INDEX over a $label", { 'public.t' => \%have }, { 'public.t' => \%want });
    like($error, $why, "... it names the reason ($label)");
    like($error, qr/^  +ALTER TABLE public\.t ADD CONSTRAINT t_a_key UNIQUE \(/m, '... and the statement that settles it');
  }

  my $error = refusal('partitioned table', model([ bare('t_a_key', 'a') ]), model([ unique('t_a_key', 'a') ]),
    { 'public.t' => { schema_name => 'public', table_name => 't', kind => 'p' } });
  like($error, qr/partitioned/, 'USING INDEX over a partitioned table: refused, and says so');

  $error = refusal('another name', model([ bare('t_idx', 'a') ]),
    model([ entry('t_idx', ['a'], constraint_name => 't_a_key', constraint_type => 'u') ]));
  like($error, qr/rename/i, 'a constraint named otherwise than the index: refused, USING INDEX would rename the index');

  $error = refusal('a second primary key', model([ pk('t_pkey', 'id') ], [ bare('t_a_idx', 'a') ]),
    model([ pk('t_pkey', 'id') ], [ entry('t_a_idx', ['a'], is_primary => 1, constraint_name => 't_a_idx', constraint_type => 'p') ]));
  like($error, qr/multiple primary keys|primary key/i, 'a primary key beside the table\'s primary key: refused');
  like($error, qr/ALTER TABLE public\.t DROP CONSTRAINT t_pkey;/, '... naming the one to drop first');
}

# ---------------------------------------------------------------------------
# 3. Another primary key under another name; changed constraints; the way back
# ---------------------------------------------------------------------------
{
  my $error = refusal('primary key renamed', model([ pk('t_pkey', 'id') ]), model([ pk('t_pk', 'id', 'a') ]));
  like($error, qr/index t_pk on public\.t is the index of the PRIMARY KEY constraint t_pk/, 'a primary key of another name: names it');
  like($error, qr/^  +ALTER TABLE public\.t DROP CONSTRAINT t_pkey;$/m, '... and the constraint to drop first (the diff creates before it drops)');

  # same name, other columns: dropped and added, in that order, as one change
  my @ops = ops(model([ pk('t_pkey', 'id') ]), model([ pk('t_pkey', 'id', 'a') ]));
  is_deeply(sql(@ops), [
      'ALTER TABLE public.t DROP CONSTRAINT t_pkey;',
      'ALTER TABLE public.t ADD CONSTRAINT t_pkey PRIMARY KEY (id, a);',
    ], 'a primary key with other columns under its name: DROP CONSTRAINT, then ADD CONSTRAINT');
  ok($ops[0]->replaced, '... the drop is the first half of a change');

  # the order of the key columns is the key
  @ops = ops(model([ pk('t_pkey', 'a', 'b') ]), model([ pk('t_pkey', 'b', 'a') ]));
  is_deeply(sql(@ops), [
      'ALTER TABLE public.t DROP CONSTRAINT t_pkey;',
      'ALTER TABLE public.t ADD CONSTRAINT t_pkey PRIMARY KEY (b, a);',
    ], 'the same columns in another order are another primary key');

  # same index text, another kind of constraint
  @ops = ops(model([ unique('t_a_key', 'a') ]), model([ entry('t_a_key', ['a'], is_primary => 1, constraint_name => 't_a_key', constraint_type => 'p') ]));
  is_deeply(sql(@ops), [
      'ALTER TABLE public.t DROP CONSTRAINT t_a_key;',
      'ALTER TABLE public.t ADD CONSTRAINT t_a_key PRIMARY KEY (a);',
    ], 'UNIQUE made PRIMARY KEY over the same text: the constraint is changed, though the definitions agree');

  # a unique constraint changed
  @ops = ops(model([ unique('t_a_key', 'a') ]), model([ unique('t_a_key', 'a', 'b') ]));
  is_deeply(sql(@ops), [
      'ALTER TABLE public.t DROP CONSTRAINT t_a_key;',
      'ALTER TABLE public.t ADD CONSTRAINT t_a_key UNIQUE (a, b);',
    ], 'a UNIQUE constraint with other columns under its name: dropped and added');

  # the way back: the target has the index, not the constraint -- also over the same text
  @ops = ops(model([ unique('t_a_key', 'a') ]), model([ bare('t_a_key', 'a') ]));
  is_deeply(sql(@ops), [
      'ALTER TABLE public.t DROP CONSTRAINT t_a_key;',
      'CREATE UNIQUE INDEX t_a_key ON public.t USING btree (a);',
    ], 'a constraint the target has as a plain index: the constraint goes, the index is created as an index');
  @ops = ops(model([ pk('t_pkey', 'id') ]), model([ bare('t_pkey', 'id', 'a') ]));
  is_deeply(sql(@ops), [
      'ALTER TABLE public.t DROP CONSTRAINT t_pkey;',
      'CREATE UNIQUE INDEX t_pkey ON public.t USING btree (id, a);',
    ], '... never a second primary key: the create stays an index');

  # a foreign key points at the constraint: the change is refused, as the drop is
  my @by = ({ schema_name => 'public', table_name => 'o', constraint_name => 'o_t_fkey' });
  $error = refusal('referenced', model([ entry('t_pkey', ['id'], is_primary => 1, constraint_name => 't_pkey', constraint_type => 'p', referenced_by => \@by) ]),
    model([ pk('t_pkey', 'id', 'a') ]));
  like($error, qr/^  +ALTER TABLE public\.o DROP CONSTRAINT o_t_fkey;$/m, 'a changed constraint a foreign key points at: refused, naming the foreign key');
  unlike($error, qr/ADD CONSTRAINT t_pkey PRIMARY KEY \(id, a\)/, '... it is not asked to change the constraint it cannot');
}

# ---------------------------------------------------------------------------
# 4. A table that goes takes its keys with it
# ---------------------------------------------------------------------------
{
  my @ops = DBIO::PostgreSQL::Diff::Index->diff(model([ pk('t_pkey', 'id') ]), {}, $TABLES, {});
  is(scalar @ops, 0, 'no statement for the keys of a table that is dropped');
}

# ---------------------------------------------------------------------------
# 5. Built by hand
# ---------------------------------------------------------------------------
{
  my %info = pk('t_pkey', 'id');
  my $op = DBIO::PostgreSQL::Diff::Index->new(
    action => 'create', table_key => 'public.t', schema_name => 'public', table_name => 't',
    index_name => 't_pkey', index_info => $info{t_pkey});
  is($op->as_sql, 'CREATE UNIQUE INDEX t_pkey ON public.t USING btree (id);',
    'an operation built by hand without via writes the definition, as it always did');
}

done_testing;
