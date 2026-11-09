use strict;
use warnings;

use Test::More;

use DBIO::PostgreSQL::DDL;
use DBIO::PostgreSQL::Diff;
use DBIO::PostgreSQL::Diff::Index;

# karr k147: DEFERRABLE / INITIALLY DEFERRED are in the model of a FOREIGN KEY
# and a UNIQUE constraint (deferrable, initially_deferred), the install writes
# them, the diff compares and writes them. Without a server;
# t/181-deferrable-live.t has each claim measured.
#
# WHY it exists: the model read condeferrable for a foreign key and nothing
# for a UNIQUE constraint, and neither the install nor the diff wrote it. A key
# made DEFERRABLE by hand lost it where the diff had to create it, and a key
# that changed to or from DEFERRABLE was "no changes".

# ---------------------------------------------------------------------------
# 1. The install
# ---------------------------------------------------------------------------
my $n = 0;
sub fresh {
  my $pkg = 'T180::P' . ++$n;
  eval "package ${pkg}::Schema; use base q(DBIO::Schema); 1" or die $@;
  "${pkg}::Schema"->load_components('PostgreSQL');
  my $parent = "${pkg}::Result::Parent";
  eval "package $parent; use base q(DBIO::Core); 1" or die $@;
  $parent->load_components('PostgreSQL::Result');
  $parent->table('parent');
  $parent->add_columns(id => { data_type => 'integer' });
  $parent->set_primary_key('id');
  "${pkg}::Schema"->register_class(Parent => $parent);
  return $pkg;
}

# A child with a belongs_to (%attrs) and a UNIQUE constraint over code; the
# options of that constraint are given to pg_unique_options when there are any.
sub child {
  my ($pkg, $attrs, $unique) = @_;
  my $class = "${pkg}::Result::Child";
  eval "package $class; use base q(DBIO::Core); 1" or die $@;
  $class->load_components('PostgreSQL::Result');
  $class->table('child');
  $class->add_columns(
    id        => { data_type => 'integer' },
    parent_id => { data_type => 'integer' },
    code      => { data_type => 'text' },
  );
  $class->set_primary_key('id');
  $class->belongs_to(parent => "${pkg}::Result::Parent", 'parent_id', $attrs // {});
  $class->add_unique_constraint(child_code_key => ['code']);
  $class->pg_unique_options(child_code_key => $unique) if $unique;
  "${pkg}::Schema"->register_class(Child => $class);
  return "${pkg}::Schema";
}

sub ddl {
  my ($pkg, $attrs, $unique) = @_;
  my $schema = child($pkg, $attrs, $unique);
  my $sql = eval { DBIO::PostgreSQL::DDL->install_ddl($schema) };
  return wantarray ? ($sql, $@) : $sql;
}

{
  my $sql = ddl(fresh());
  like($sql, qr/FOREIGN KEY \(parent_id\) REFERENCES parent \(id\);/, 'no declaration: the foreign key has no timing clause');
  like($sql, qr/CONSTRAINT child_code_key UNIQUE \(code\)\n/, '... nor has the UNIQUE constraint');
  unlike($sql, qr/DEFERRABLE/i, '... DEFERRABLE is nowhere (no change for an existing schema)');

  $sql = ddl(fresh(), { deferrable => 1 }, { deferrable => 1 });
  like($sql, qr/FOREIGN KEY \(parent_id\) REFERENCES parent \(id\) DEFERRABLE INITIALLY IMMEDIATE;/,
    'belongs_to deferrable => 1: DEFERRABLE INITIALLY IMMEDIATE');
  like($sql, qr/CONSTRAINT child_code_key UNIQUE \(code\) DEFERRABLE INITIALLY IMMEDIATE\n/,
    'pg_unique_options deferrable => 1: the same on the UNIQUE constraint');

  $sql = ddl(fresh(), { deferrable => 1, initially_deferred => 1, on_delete => 'CASCADE' },
    { deferrable => 1, initially_deferred => 1 });
  like($sql, qr/REFERENCES parent \(id\) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;/,
    'initially_deferred => 1: INITIALLY DEFERRED, behind the actions');
  like($sql, qr/CONSTRAINT child_code_key UNIQUE \(code\) DEFERRABLE INITIALLY DEFERRED\n/, '... and on the UNIQUE constraint');

  $sql = ddl(fresh(), { deferrable => 0, initially_deferred => 0 }, { deferrable => 0 });
  unlike($sql, qr/DEFERRABLE/i, 'both 0: not deferrable, no clause');
}

# initially_deferred without deferrable: PostgreSQL refuses it; the install does first
{
  my ($sql, $err) = ddl(fresh(), { initially_deferred => 1 });
  ok(!defined $sql, 'belongs_to initially_deferred without deferrable: no script');
  like($err, qr/refusing to write the install DDL: relationship 'parent' of child .*initially_deferred.*deferrable/,
    '... the refusal names the relationship and the missing deferrable');

  ($sql, $err) = ddl(fresh(), {}, { initially_deferred => 1 });
  ok(!defined $sql, 'pg_unique_options initially_deferred without deferrable: no script');
  like($err, qr/refusing to write the install DDL: .*child_code_key.*initially_deferred.*deferrable/,
    '... the refusal names the constraint');

  ($sql, $err) = ddl(fresh(), {}, { deferrable => 1, bogus => 1 });
  like($err, qr/refusing to write the install DDL: .*child_code_key.*bogus/, 'an unknown option is refused by name');

  my $pkg = fresh();
  my $schema = child($pkg);
  "${pkg}::Result::Child"->pg_unique_options(no_such_key => { deferrable => 1 });
  $sql = eval { DBIO::PostgreSQL::DDL->install_ddl($schema) };
  like($@, qr/refusing to write the install DDL: .*no_such_key/, 'options for a UNIQUE constraint the table does not have are refused by name');
}

# ---------------------------------------------------------------------------
# 2. The diff of a foreign key
# ---------------------------------------------------------------------------
sub table { my ($t) = @_; return ("public.$t" => { schema_name => 'public', table_name => $t, kind => 'r' }) }

sub fk {
  my ($name, %more) = @_;
  return {
    constraint_name => $name, remote_schema => 'public', remote_table => 'parent',
    local_columns => ['parent_id'], remote_columns => ['id'],
    on_delete => 'NO ACTION', on_update => 'NO ACTION', is_deferrable => 0,
    %more,
  };
}

sub fkdiff {
  my ($src, $tgt) = @_;
  my $model = sub { { tables => { map { table($_) } qw( parent child ) }, foreign_keys => { 'public.child' => [ $_[0] ] } } };
  return DBIO::PostgreSQL::Diff->new(source => $model->($src), target => $model->($tgt));
}

sub sql { return [ map { $_->as_sql } @{ $_[0]->operations } ] }

{
  my $d = DBIO::PostgreSQL::Diff->new(
    source => { tables => { map { table($_) } qw( parent child ) }, foreign_keys => {} },
    target => { tables => { map { table($_) } qw( parent child ) },
      foreign_keys => { 'public.child' => [ fk('c_fk', deferrable => 1, initially_deferred => 1) ] } });
  is_deeply(sql($d), [
      'ALTER TABLE public.child ADD CONSTRAINT c_fk FOREIGN KEY (parent_id) REFERENCES public.parent (id) DEFERRABLE INITIALLY DEFERRED;',
    ], 'a key of the target is created with DEFERRABLE INITIALLY DEFERRED');

  $d = DBIO::PostgreSQL::Diff->new(
    source => { tables => { map { table($_) } qw( parent child ) }, foreign_keys => {} },
    target => { tables => { map { table($_) } qw( parent child ) },
      foreign_keys => { 'public.child' => [ fk('c_fk', deferrable => 1, initially_deferred => 0, on_delete => 'CASCADE') ] } });
  is_deeply(sql($d), [
      'ALTER TABLE public.child ADD CONSTRAINT c_fk FOREIGN KEY (parent_id) REFERENCES public.parent (id) ON DELETE CASCADE DEFERRABLE INITIALLY IMMEDIATE;',
    ], 'deferrable only: INITIALLY IMMEDIATE, behind the actions');

  $d = fkdiff(fk('c_fk', deferrable => 1, initially_deferred => 1), fk('c_fk', deferrable => 1, initially_deferred => 1));
  ok(!$d->has_changes, 'the same timing on both sides is no operation');

  for my $case (
    [ 'NOT DEFERRABLE to DEFERRABLE',  {},                                              { deferrable => 1 } ],
    [ 'DEFERRABLE to NOT DEFERRABLE',  { deferrable => 1 },                             {} ],
    [ 'IMMEDIATE to DEFERRED',         { deferrable => 1 },                             { deferrable => 1, initially_deferred => 1 } ],
    [ 'DEFERRED to IMMEDIATE',         { deferrable => 1, initially_deferred => 1 },    { deferrable => 1 } ],
  ) {
    my ($label, $old, $new) = @$case;
    $d = fkdiff(fk('c_fk', %$old), fk('c_fk', %$new));
    my @sql = @{ sql($d) };
    is(scalar(@sql), 2, "$label: a drop and a create");
    like($sql[0], qr/^ALTER TABLE public\.child DROP CONSTRAINT c_fk;$/, '... the drop first');
    like($sql[1], qr/^ALTER TABLE public\.child ADD CONSTRAINT c_fk FOREIGN KEY/, '... then the create');
  }

  # A model that still says is_deferrable only (built by hand, older) is read as deferrable.
  $d = fkdiff(fk('c_fk', is_deferrable => 1), fk('c_fk', deferrable => 1));
  ok(!$d->has_changes, 'is_deferrable alone in a model is read as deferrable (no change against the new key)');
  $d = fkdiff(fk('c_fk'), fk('c_fk', is_deferrable => 1));
  is(scalar(@{ sql($d) }), 2, '... and a change against an old-style key is a change');
}

# ---------------------------------------------------------------------------
# 3. The diff of a UNIQUE constraint
# ---------------------------------------------------------------------------
my $TABLES = { 'public.t' => { schema_name => 'public', table_name => 't', kind => 'r' } };

sub unique {
  my ($name, $columns, %more) = @_;
  return ($name => {
    index_name => $name, access_method => 'btree', is_unique => 1, is_primary => 0, is_valid => 1,
    definition => "CREATE UNIQUE INDEX $name ON public.t USING btree (" . join(', ', @$columns) . ')',
    predicate => undef, expressions => undef, columns => $columns, include_columns => [],
    storage_params => {}, opclasses => {}, sort_options => {},
    constraint_name => $name, constraint_type => 'u', referenced_by => [],
    %more,
  });
}
sub model { return { 'public.t' => { map { @$_ } @_ } } }
sub idx { return [ DBIO::PostgreSQL::Diff::Index->diff($_[0], $_[1], $TABLES, $TABLES) ] }
sub idxsql { return [ map { $_->as_sql } @{ $_[0] } ] }

{
  my $ops = idx({}, model([ unique('t_a_key', ['a'], deferrable => 1, initially_deferred => 1) ]));
  is_deeply(idxsql($ops), ['ALTER TABLE public.t ADD CONSTRAINT t_a_key UNIQUE (a) DEFERRABLE INITIALLY DEFERRED;'],
    'a UNIQUE constraint of the target is created DEFERRABLE INITIALLY DEFERRED');

  $ops = idx({}, model([ unique('t_a_key', ['a'], deferrable => 1) ]));
  is_deeply(idxsql($ops), ['ALTER TABLE public.t ADD CONSTRAINT t_a_key UNIQUE (a) DEFERRABLE INITIALLY IMMEDIATE;'],
    'deferrable only: INITIALLY IMMEDIATE');

  $ops = idx({}, model([ unique('t_a_key', ['a']) ]));
  is_deeply(idxsql($ops), ['ALTER TABLE public.t ADD CONSTRAINT t_a_key UNIQUE (a);'], 'not deferrable: no clause');

  $ops = idx(model([ unique('t_a_key', ['a'], deferrable => 1) ]), model([ unique('t_a_key', ['a'], deferrable => 1) ]));
  is(scalar(@$ops), 0, 'the same timing on both sides: nothing');

  for my $case (
    [ 'NOT DEFERRABLE to DEFERRABLE', {},                                           { deferrable => 1 } ],
    [ 'DEFERRABLE to NOT DEFERRABLE', { deferrable => 1 },                          {} ],
    [ 'IMMEDIATE to DEFERRED',        { deferrable => 1 },                          { deferrable => 1, initially_deferred => 1 } ],
  ) {
    my ($label, $old, $new) = @$case;
    $ops = idx(model([ unique('t_a_key', ['a'], %$old) ]), model([ unique('t_a_key', ['a'], %$new) ]));
    my @sql = @{ idxsql($ops) };
    is(scalar(@sql), 2, "$label: a drop and a create");
    is($sql[0], 'ALTER TABLE public.t DROP CONSTRAINT t_a_key;', '... the constraint dropped first');
    like($sql[1], qr/^ALTER TABLE public\.t ADD CONSTRAINT t_a_key UNIQUE \(a\)/, '... then created');
    is($sql[1] =~ /DEFERRABLE/ ? 1 : 0, ($new->{deferrable} ? 1 : 0), '... with the target\'s timing');
  }

  # The database has the key as a unique index only: USING INDEX takes the timing too
  my $bare = { unique('t_a_key', ['a'], constraint_name => undef, constraint_type => undef) };
  $ops = idx(model([ %$bare ]), model([ unique('t_a_key', ['a'], deferrable => 1, initially_deferred => 1) ]));
  is_deeply(idxsql($ops), ['ALTER TABLE public.t ADD CONSTRAINT t_a_key UNIQUE USING INDEX t_a_key DEFERRABLE INITIALLY DEFERRED;'],
    'ADD CONSTRAINT ... USING INDEX carries the timing');

  # A plain rename keeps the timing; a rename that changes it is a drop and a create
  $ops = idx(model([ unique('t_old_key', ['a'], deferrable => 1) ]), model([ unique('t_a_key', ['a'], deferrable => 1) ]));
  is_deeply(idxsql($ops), ['ALTER TABLE public.t RENAME CONSTRAINT t_old_key TO t_a_key;'],
    'a rename that keeps the timing is a RENAME CONSTRAINT');

  for my $case (
    [ 'rename and NOT DEFERRABLE to DEFERRABLE', {},                  { deferrable => 1 } ],
    [ 'rename and DEFERRABLE to NOT DEFERRABLE', { deferrable => 1 }, {} ],
    [ 'rename and IMMEDIATE to DEFERRED',        { deferrable => 1 }, { deferrable => 1, initially_deferred => 1 } ],
  ) {
    my ($label, $old, $new) = @$case;
    $ops = idx(model([ unique('t_old_key', ['a'], %$old) ]), model([ unique('t_a_key', ['a'], %$new) ]));
    my @sql = @{ idxsql($ops) };
    is(scalar(@sql), 2, "$label: a drop and a create, no rename");
    is($sql[0], 'ALTER TABLE public.t DROP CONSTRAINT t_old_key;', '... the old constraint dropped first');
    ok($ops->[0]->replaced, '... the drop is replaced');
    like($sql[1], qr/^ALTER TABLE public\.t ADD CONSTRAINT t_a_key UNIQUE \(a\)/, '... then the target created');
    is($sql[1] =~ /DEFERRABLE/ ? 1 : 0, ($new->{deferrable} ? 1 : 0), '... with the target\'s timing');
  }
}

done_testing;
