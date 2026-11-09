use strict;
use warnings;

use Test::More;

use DBIO::PostgreSQL::Diff;
use DBIO::PostgreSQL::DDL;

# karr k140: the diff compares foreign keys and writes them. Without a server;
# t/160-diff-foreign-key-live.t has each claim measured.
#
# WHY it exists: the install writes a FOREIGN KEY for a belongs_to
# (pg_fk_constraints_from_rels) with its ON DELETE / ON UPDATE, and the diff
# knew none: a table the upgrade created had no foreign key, a changed action
# was "no changes", and a key the schema does not declare stayed for ever.
# These are the claims about what the diff builds from two models.

sub table { my ($n) = @_; return ("public.$n" => { schema_name => 'public', table_name => $n, kind => 'r' }) }

sub fk {
  my ($name, %more) = @_;
  return {
    constraint_name => $name,
    remote_schema   => 'public',
    remote_table    => 'parent',
    local_columns   => ['parent_id'],
    remote_columns  => ['id'],
    on_delete       => 'NO ACTION',
    on_update       => 'NO ACTION',
    is_deferrable   => 0,
    %more,
  };
}

# A diff of two models that hold tables and foreign keys. $fks undef = the
# model has no section at all (a model built by hand, not read from a server).
sub diff {
  my ($src, $tgt, %opt) = @_;
  my $model = sub {
    my ($t, $f) = @{ $_[0] };
    return { tables => { map { table($_) } @$t }, (defined $f ? (foreign_keys => $f) : ()) };
  };
  return DBIO::PostgreSQL::Diff->new(source => $model->($src), target => $model->($tgt), %opt);
}

sub sql { return [ map { $_->as_sql } @{ $_[0]->operations } ] }

# Only the statements about a constraint: CREATE TABLE and DROP TABLE are another class's.
sub fksql { return [ grep { /CONSTRAINT/ } @{ sql($_[0]) } ] }

# ---------------------------------------------------------------------------
# 1. A foreign key the target has and the database lacks, on a table both have
# ---------------------------------------------------------------------------
{
  my $d = diff([ [qw( parent child )], {} ],
    [ [qw( parent child )], { 'public.child' => [ fk('child_parent_id_fkey', on_delete => 'CASCADE', on_update => 'SET NULL') ] } ]);
  is_deeply(sql($d), [
      'ALTER TABLE public.child ADD CONSTRAINT child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.parent (id) ON DELETE CASCADE ON UPDATE SET NULL;',
    ], 'a foreign key of the target is created, with the actions the target carries');
  is($d->summary, '  +fk: child_parent_id_fkey (on public.child -> public.parent)', '... and the summary names it');

  $d = diff([ [qw( parent child )], {} ],
    [ [qw( parent child )], { 'public.child' => [ fk('child_parent_id_fkey') ] } ]);
  is_deeply(sql($d), [
      'ALTER TABLE public.child ADD CONSTRAINT child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.parent (id);',
    ], 'NO ACTION is the server default and is written as no clause');
}

# ---------------------------------------------------------------------------
# 2. Several columns, names that need quotes, another schema
# ---------------------------------------------------------------------------
{
  my $f = fk('Order Line_a_b_fkey', remote_schema => 'other', remote_table => 'Parent Tbl',
    local_columns => [qw( a B )], remote_columns => [qw( x y )]);
  my $d = diff([ [qw( parent )], {} ], [ [qw( parent )], { 'public.parent' => [$f] } ]);
  is_deeply(sql($d), [
      'ALTER TABLE public.parent ADD CONSTRAINT "Order Line_a_b_fkey" FOREIGN KEY (a, "B") REFERENCES other."Parent Tbl" (x, y);',
    ], 'columns keep their order, names are written as identifiers by the server rule');
}

# ---------------------------------------------------------------------------
# 3. A table the diff creates gets its foreign key
# ---------------------------------------------------------------------------
{
  my $d = diff([ [qw( parent )], {} ],
    [ [qw( parent child )], { 'public.child' => [ fk('child_parent_id_fkey', on_delete => 'CASCADE') ] } ]);
  is_deeply(fksql($d), [
      'ALTER TABLE public.child ADD CONSTRAINT child_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.parent (id) ON DELETE CASCADE;',
    ], 'the foreign key of a table the diff creates is created too (U4)');
}

# ---------------------------------------------------------------------------
# 4. Nothing changed, a change of any part
# ---------------------------------------------------------------------------
{
  my $same = { 'public.child' => [ fk('c_fk', on_delete => 'CASCADE') ] };
  ok(!diff([ [qw( parent child )], $same ], [ [qw( parent child )], { 'public.child' => [ fk('c_fk', on_delete => 'CASCADE') ] } ])->has_changes,
    'the same foreign key on both sides is no operation');

  for my $change (
    [ on_delete      => 'SET NULL' ],
    [ on_update      => 'CASCADE' ],
    [ remote_table   => 'other' ],
    [ remote_schema  => 'other' ],
    [ local_columns  => ['other_id'] ],
    [ remote_columns => ['pk'] ],
  ) {
    my ($field, $value) = @$change;
    my $d = diff([ [qw( parent child )], $same ],
      [ [qw( parent child )], { 'public.child' => [ fk('c_fk', on_delete => 'CASCADE', $field => $value) ] } ]);
    my @sql = @{ sql($d) };
    is(scalar(@sql), 2, "$field changed: a drop and a create");
    like($sql[0], qr/^ALTER TABLE public\.child DROP CONSTRAINT c_fk;$/, '... the drop first');
    like($sql[1], qr/^ALTER TABLE public\.child ADD CONSTRAINT c_fk FOREIGN KEY/, '... then the create, under the same name');
    is($d->classify->{class}, 'changing', '... a change, not a destruction');
  }

  # DEFERRABLE is in the model and compared (karr k147; t/183-deferrable.t has the rest).
  ok(diff([ [qw( parent child )], { 'public.child' => [ fk('c_fk') ] } ],
      [ [qw( parent child )], { 'public.child' => [ fk('c_fk', deferrable => 1) ] } ])->has_changes,
    'DEFERRABLE is compared');
}

# ---------------------------------------------------------------------------
# 5. A foreign key the schema does not declare is dropped, and the summary says so
# ---------------------------------------------------------------------------
{
  my $d = diff([ [qw( parent child )], { 'public.child' => [ fk('hand_made_fkey') ] } ],
    [ [qw( parent child )], { 'public.child' => [] } ]);
  is_deeply(sql($d), ['ALTER TABLE public.child DROP CONSTRAINT hand_made_fkey;'], 'a foreign key the target lacks is dropped');
  like($d->summary, qr/^  -fk: hand_made_fkey \(on public\.child -> public\.parent\) -- not declared by the schema, dropped$/,
    '... and the summary says it is not declared');
  is($d->classify->{class}, 'destructive', '... a destructive diff');

  # The last foreign key of a table: the target has no entry for the table at all.
  $d = diff([ [qw( parent child )], { 'public.child' => [ fk('hand_made_fkey') ] } ],
    [ [qw( parent child )], {} ]);
  is_deeply(sql($d), ['ALTER TABLE public.child DROP CONSTRAINT hand_made_fkey;'],
    'the last foreign key of a table is dropped though the target has no entry for the table (U11)');
}

# ---------------------------------------------------------------------------
# 6. A target that says nothing about foreign keys drops none
# ---------------------------------------------------------------------------
{
  my $d = diff([ [qw( parent child )], { 'public.child' => [ fk('c_fk') ] } ], [ [qw( parent child )], undef ]);
  ok(!$d->has_changes, 'a target model without the foreign_keys section is not read as "declares none": no drop');
}

# ---------------------------------------------------------------------------
# 7. Tables that go
# ---------------------------------------------------------------------------
{
  my $d = diff([ [qw( parent child )], { 'public.child' => [ fk('c_fk') ] } ], [ [qw( parent )], {} ]);
  is_deeply(fksql($d), [], 'the foreign key of a dropped table goes with the table, no statement of its own');

  $d = diff([ [qw( parent child )], { 'public.child' => [ fk('c_fk') ] } ], [ [qw( child )], {} ]);
  is_deeply(fksql($d), ['ALTER TABLE public.child DROP CONSTRAINT c_fk;'],
    'a foreign key of a table that stays, into a table that is dropped, is dropped');
}

# ---------------------------------------------------------------------------
# 8. NOT VALID, and VALIDATE CONSTRAINT as a step of its own (the option)
# ---------------------------------------------------------------------------
{
  my $src = [ [qw( parent child )], {} ];
  my $tgt = [ [qw( parent child )], { 'public.child' => [ fk('a_fk'), fk('b_fk', local_columns => ['b_id'], on_delete => 'CASCADE') ] } ];

  is_deeply(sql(diff($src, $tgt)), [
      'ALTER TABLE public.child ADD CONSTRAINT a_fk FOREIGN KEY (parent_id) REFERENCES public.parent (id);',
      'ALTER TABLE public.child ADD CONSTRAINT b_fk FOREIGN KEY (b_id) REFERENCES public.parent (id) ON DELETE CASCADE;',
    ], 'by default the foreign key is an ordinary ADD CONSTRAINT (no NOT VALID, no VALIDATE)');

  my $d = diff($src, $tgt, foreign_keys_not_valid => 1);
  is_deeply(sql($d), [
      'ALTER TABLE public.child ADD CONSTRAINT a_fk FOREIGN KEY (parent_id) REFERENCES public.parent (id) NOT VALID;',
      'ALTER TABLE public.child ADD CONSTRAINT b_fk FOREIGN KEY (b_id) REFERENCES public.parent (id) ON DELETE CASCADE NOT VALID;',
      'ALTER TABLE public.child VALIDATE CONSTRAINT a_fk;',
      'ALTER TABLE public.child VALIDATE CONSTRAINT b_fk;',
    ], 'with the option: every ADD ... NOT VALID, then every VALIDATE CONSTRAINT as a step of its own');
  is_deeply([ map { $_->summary } @{ $d->operations } ], [
      '  +fk: a_fk (on public.child -> public.parent) NOT VALID',
      '  +fk: b_fk (on public.child -> public.parent) NOT VALID',
      '  ~fk: a_fk (on public.child) validate',
      '  ~fk: b_fk (on public.child) validate',
    ], '... the summary shows both steps');

  # A table created in the same diff is empty: nothing to skip checking.
  $d = diff([ [qw( parent )], {} ], [ [qw( parent child )], { 'public.child' => [ fk('a_fk') ] } ], foreign_keys_not_valid => 1);
  is_deeply(fksql($d), [
      'ALTER TABLE public.child ADD CONSTRAINT a_fk FOREIGN KEY (parent_id) REFERENCES public.parent (id);',
    ], 'with the option, the key of a table the diff creates is still a plain ADD CONSTRAINT (empty table)');

  # A changed key: the drop stays ahead, the create is NOT VALID, validate follows.
  $d = diff([ [qw( parent child )], { 'public.child' => [ fk('a_fk') ] } ],
    [ [qw( parent child )], { 'public.child' => [ fk('a_fk', on_delete => 'CASCADE') ] } ], foreign_keys_not_valid => 1);
  is_deeply(sql($d), [
      'ALTER TABLE public.child DROP CONSTRAINT a_fk;',
      'ALTER TABLE public.child ADD CONSTRAINT a_fk FOREIGN KEY (parent_id) REFERENCES public.parent (id) ON DELETE CASCADE NOT VALID;',
      'ALTER TABLE public.child VALIDATE CONSTRAINT a_fk;',
    ], 'a changed key with the option: drop, add NOT VALID, validate');
}

# ---------------------------------------------------------------------------
# 9. Order against the indexes (the key a foreign key points at)
# ---------------------------------------------------------------------------
{
  # $by: what the introspection says of the key, referenced_by -- the foreign
  # keys that point at it, as the catalog gives them.
  sub pkey { my ($t, $by) = @_; return { "${t}_pkey" => {
      index_name => "${t}_pkey", access_method => 'btree', is_unique => 1, is_primary => 1, is_valid => 1,
      definition => "CREATE UNIQUE INDEX ${t}_pkey ON public.$t USING btree (id)", predicate => undef, expressions => undef,
      columns => ['id'], include_columns => [], storage_params => {}, opclasses => {}, sort_options => {},
      constraint_name => "${t}_pkey", constraint_type => 'p', referenced_by => $by // [],
      schema_name => 'public', table_name => $t } } }

  my $model = sub {
    my ($tables, $fks, $idx, $by) = @_;
    return { tables => { map { table($_) } @$tables }, foreign_keys => $fks, indexes => { map { ("public.$_" => pkey($_, $by->{$_})) } @$idx } };
  };

  my $d = DBIO::PostgreSQL::Diff->new(
    source => $model->([], {}, []),
    target => $model->([qw( parent child )], { 'public.child' => [ fk('child_parent_id_fkey') ] }, [qw( parent child )]),
  );
  my @sql = @{ sql($d) };
  my ($pk) = grep { $sql[$_] =~ /ADD CONSTRAINT parent_pkey PRIMARY KEY/ } 0..$#sql;
  my ($fkpos) = grep { $sql[$_] =~ /FOREIGN KEY/ } 0..$#sql;
  ok(defined $pk && defined $fkpos && $pk < $fkpos, 'the primary key the foreign key points at is created ahead of it');

  $d = DBIO::PostgreSQL::Diff->new(
    source => $model->([qw( parent child )], { 'public.child' => [ fk('child_parent_id_fkey') ] }, [qw( parent child )],
      { parent => [ { schema_name => 'public', table_name => 'child', constraint_name => 'child_parent_id_fkey' } ] }),
    target => $model->([qw( parent child )], { 'public.child' => [] }, [ 'child' ]),
  );
  @sql = @{ sql($d) };
  my ($drop_fk) = grep { $sql[$_] =~ /DROP CONSTRAINT child_parent_id_fkey/ } 0..$#sql;
  my ($drop_pk) = grep { $sql[$_] =~ /DROP CONSTRAINT parent_pkey/ } 0..$#sql;
  ok(defined $drop_fk && defined $drop_pk && $drop_fk < $drop_pk, 'the foreign key is dropped ahead of the key it pointed at');
}

# ---------------------------------------------------------------------------
# 10. The install and the diff write one constraint
# ---------------------------------------------------------------------------
{
  {
    package T159::Schema;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('PostgreSQL');
    package T159::Result::Customer;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('customer');
    __PACKAGE__->add_columns(id => { data_type => 'integer' });
    __PACKAGE__->set_primary_key('id');
    package T159::Result::Orders;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('orders');
    __PACKAGE__->add_columns(id => { data_type => 'integer' }, customer_id => { data_type => 'integer' });
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->belongs_to(customer => 'T159::Result::Customer', 'customer_id', { on_delete => 'cascade', on_update => 'SET NULL' });
    __PACKAGE__->pg_fk_constraints_from_rels(1);
    T159::Schema->register_class(Customer => 'T159::Result::Customer');
    T159::Schema->register_class(Orders   => 'T159::Result::Orders');
  }
  my $install = DBIO::PostgreSQL::DDL->install_ddl('T159::Schema');
  my ($line) = $install =~ /^(ALTER TABLE \S+ ADD CONSTRAINT \S+ FOREIGN KEY .*;)$/m;
  ok($line, 'the install writes the foreign key') or diag $install;

  # What the server reads back from that: the name, the tables and the columns
  # are the install's own, taken from its output and not written out again
  # here; the action words come back in capitals.
  my ($name, $lcols, $rtable, $rcols) = $line =~
    /ADD CONSTRAINT (\S+) FOREIGN KEY \(([^)]*)\) REFERENCES (?:public\.)?(\S+) \(([^)]*)\)/;
  my $cols = sub { [ map { s/^"|"$//gr } split /, /, $_[0] ] };
  my $d = diff([ [qw( customer orders )], {} ], [ [qw( customer orders )], {
        'public.orders' => [ fk($name, remote_table => $rtable, local_columns => $cols->($lcols),
          remote_columns => $cols->($rcols), on_delete => 'CASCADE', on_update => 'SET NULL') ] } ]);
  my ($diff_sql) = grep { /CONSTRAINT/ } @{ sql($d) };
  $diff_sql =~ s/public\.//g;
  (my $inst_sql = $line) =~ s/ ON DELETE cascade/ ON DELETE CASCADE/;
  is($diff_sql, $inst_sql, 'the diff writes the constraint of the install: same name, same columns, same actions');
}

# ---------------------------------------------------------------------------
# 11. An action word the server does not know is refused where it is declared
# ---------------------------------------------------------------------------
{
  for my $bad (qw( CASCADEE DELETE ), 'SET  NOTHING', 'cascade; DROP TABLE x') {
    my $info = T159::Schema->source('Orders')->relationship_info('customer');
    local $info->{attrs}{on_delete} = $bad;
    my $ddl = eval { DBIO::PostgreSQL::DDL->install_ddl('T159::Schema') };
    ok(!defined $ddl, "on_delete => '$bad': no install DDL");
    like($@, qr/refusing to write the install DDL: .*on_delete.*\Q$bad\E.*NO ACTION, RESTRICT, CASCADE, SET NULL, SET DEFAULT/s,
      '... the refusal names the value and the five words');
  }
  for my $good ('no action', 'RESTRICT', 'Cascade', 'set null', 'SET DEFAULT') {
    my $info = T159::Schema->source('Orders')->relationship_info('customer');
    local $info->{attrs}{on_update} = $good;
    my $ddl = eval { DBIO::PostgreSQL::DDL->install_ddl('T159::Schema') };
    like($ddl // '', qr/ON UPDATE \Q$good\E;/, "on_update => '$good' is written as declared") or diag $@;
  }
}

# ---------------------------------------------------------------------------
# 12. Validity (convalidated), MATCH, and the column list of SET NULL / SET DEFAULT
# ---------------------------------------------------------------------------
{
  my $both = sub {
    my ($s, $t, %o) = @_;
    return diff([ [qw( parent child )], { 'public.child' => [ $s ] } ], [ [qw( parent child )], { 'public.child' => [ $t ] } ], %o);
  };

  my $d = $both->(fk('c_fk', is_valid => 0), fk('c_fk', is_valid => 1));
  is_deeply(sql($d), [ 'ALTER TABLE public.child VALIDATE CONSTRAINT c_fk;' ],
    'a key the database has NOT VALID, the target valid: VALIDATE CONSTRAINT, no drop, no create');
  is($d->summary, '  ~fk: c_fk (on public.child) validate', '... named in the summary');

  $d = $both->(fk('c_fk', is_valid => 0), fk('c_fk'));
  is_deeply(sql($d), [ 'ALTER TABLE public.child VALIDATE CONSTRAINT c_fk;' ], 'a target without the field holds a valid key');

  $d = $both->(fk('c_fk', is_valid => 0), fk('c_fk'), foreign_keys_not_valid => 1);
  is_deeply(sql($d), [ 'ALTER TABLE public.child VALIDATE CONSTRAINT c_fk;' ],
    'with foreign_keys_not_valid: still the one validate, no NOT VALID added to it');

  ok(!$both->(fk('c_fk', is_valid => 0), fk('c_fk', is_valid => 0))->has_changes, 'not valid on both sides: no change');
  ok(!$both->(fk('c_fk'), fk('c_fk', is_valid => 1))->has_changes, 'valid on both sides, field present or not: no change');
  ok(!$both->(fk('c_fk', is_valid => 1), fk('c_fk', is_valid => 0))->has_changes, 'valid in the database, not valid in the target: nothing to do');

  $d = $both->(fk('c_fk', is_valid => 0), fk('c_fk', on_delete => 'CASCADE'));
  is_deeply(sql($d), [
      'ALTER TABLE public.child DROP CONSTRAINT c_fk;',
      'ALTER TABLE public.child ADD CONSTRAINT c_fk FOREIGN KEY (parent_id) REFERENCES public.parent (id) ON DELETE CASCADE;',
    ], 'not valid and changed: dropped and created again, no validate of its own');

  $d = $both->(fk('c_fk'), fk('c_fk', match => 'FULL'));
  is_deeply(sql($d), [
      'ALTER TABLE public.child DROP CONSTRAINT c_fk;',
      'ALTER TABLE public.child ADD CONSTRAINT c_fk FOREIGN KEY (parent_id) REFERENCES public.parent (id) MATCH FULL;',
    ], 'MATCH FULL against the default: dropped and created, the create says MATCH FULL');
  ok(!$both->(fk('c_fk'), fk('c_fk', match => 'SIMPLE'))->has_changes, 'MATCH SIMPLE is the default');

  $d = $both->(fk('c_fk', on_delete => 'SET NULL'), fk('c_fk', on_delete => 'SET NULL', on_delete_columns => ['parent_id']));
  is_deeply(sql($d), [
      'ALTER TABLE public.child DROP CONSTRAINT c_fk;',
      'ALTER TABLE public.child ADD CONSTRAINT c_fk FOREIGN KEY (parent_id) REFERENCES public.parent (id) ON DELETE SET NULL (parent_id);',
    ], 'ON DELETE SET NULL (cols) against SET NULL: dropped and created, with the column list');
  $d = $both->(fk('c_fk', on_delete => 'SET DEFAULT', on_delete_columns => ['a']), fk('c_fk', on_delete => 'SET DEFAULT', on_delete_columns => ['a', 'b']));
  like(sql($d)->[1], qr/ON DELETE SET DEFAULT \(a, b\);$/, 'SET DEFAULT (cols): a changed list is a changed key, the list is written');
  ok(!$both->(fk('c_fk', on_delete => 'SET NULL', on_delete_columns => []), fk('c_fk', on_delete => 'SET NULL'))->has_changes,
    'an empty list is no list');

  $d = diff([ [qw( parent child )], {} ], [ [qw( parent child )], { 'public.child' =>
    [ fk('c_fk', match => 'FULL', on_delete => 'SET NULL', on_delete_columns => ['parent_id'], on_update => 'CASCADE') ] } ]);
  is_deeply(sql($d), [ 'ALTER TABLE public.child ADD CONSTRAINT c_fk FOREIGN KEY (parent_id) REFERENCES public.parent (id) MATCH FULL ON DELETE SET NULL (parent_id) ON UPDATE CASCADE;' ],
    'a new key is written with all of it, in the order of the server\'s grammar');
}

# ---------------------------------------------------------------------------
# 13. A key into a table outside the deploy is not the deploy's (karr k140)
# ---------------------------------------------------------------------------
{
  my $ext = sub { fk('child_ext_id_fkey', remote_schema => 'other', remote_table => 'ext', local_columns => ['ext_id']) };
  my $d = diff([ [qw( parent child )], { 'public.child' => [ $ext->() ] } ],
    [ [qw( parent child )], { 'public.child' => [] } ]);
  is_deeply(fksql($d), [], 'a key into a table in neither model is not dropped');
  ok(!$d->has_changes, '... and is no change');
  like($d->summary, qr/^  =fk: child_ext_id_fkey \(on public\.child -> other\.ext\) -- kept \(target outside the deploy\)$/m,
    '... the summary names it as kept');

  $d = diff([ [qw( parent child )], { 'public.child' => [ $ext->(), fk('hand_made_fkey') ] } ],
    [ [qw( parent child )], { 'public.child' => [] } ]);
  is_deeply(fksql($d), ['ALTER TABLE public.child DROP CONSTRAINT hand_made_fkey;'],
    'an undeclared key between two deployed tables is still dropped');
  like($d->summary, qr/kept \(target outside the deploy\)/, '... beside the one kept');

  $d = diff([ [qw( parent child )], { 'public.child' => [ $ext->() ] } ],
    [ [qw( parent child )], { 'public.child' => [ $ext->() ] } ]);
  ok(!$d->has_changes && $d->summary =~ /kept/, 'a key both models hold is kept too, not compared');

  $d = diff([ [qw( parent child )], { 'public.child' => [ fk('c_fk') ] } ], [ [qw( child )], {} ]);
  is_deeply(fksql($d), ['ALTER TABLE public.child DROP CONSTRAINT c_fk;'],
    'a key into a table only the source has (dropped) is inside the deploy, dropped');
  unlike($d->summary, qr/kept/, '... and not called kept');

  $d = diff([ [qw( child )], { 'public.child' => [ fk('c_fk') ] } ], [ [qw( parent child )], {} ]);
  is_deeply(fksql($d), ['ALTER TABLE public.child DROP CONSTRAINT c_fk;'],
    'a key into a table only the target has (created) is inside the deploy, dropped');
  unlike($d->summary, qr/kept/, '... and not called kept');

  $d = diff([ [qw( parent child )], { 'public.child' => [ $ext->() ] } ], [ [qw( parent child )], undef ]);
  unlike($d->summary, qr/kept/, 'a target without the section keeps nothing: it drops nothing either');

  # A key of the database into a table outside both models, whose name the
  # target declares too but onto a table inside the deploy, is a redefinition
  # of the key, not the same key kept: the database's one is dropped, the
  # target's created.
  $d = diff([ [qw( parent child )], { 'public.child' => [ $ext->() ] } ],
    [ [qw( parent child )], { 'public.child' => [ fk('child_ext_id_fkey', local_columns => ['ext_id']) ] } ]);
  is_deeply(fksql($d), [
      'ALTER TABLE public.child DROP CONSTRAINT child_ext_id_fkey;',
      'ALTER TABLE public.child ADD CONSTRAINT child_ext_id_fkey FOREIGN KEY (ext_id) REFERENCES public.parent (id);',
    ], 'a key kept by its target outside the deploy, declared under the same name onto a deployed table, is replaced');
  unlike($d->summary, qr/kept/, '... and not called kept');
  ok($d->has_changes, '... it is a change');
}

# ---------------------------------------------------------------------------
# 14. is_foreign_key_constraint => 0 on a belongs_to writes no key
# ---------------------------------------------------------------------------
{
  {
    package T159B::Schema;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('PostgreSQL');
    package T159B::Result::Customer;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('customer');
    __PACKAGE__->add_columns(id => { data_type => 'integer' });
    __PACKAGE__->set_primary_key('id');
    package T159B::Result::Orders;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('orders');
    __PACKAGE__->add_columns(id => { data_type => 'integer' }, customer_id => { data_type => 'integer' },
      shipper_id => { data_type => 'integer' });
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->belongs_to(customer => 'T159B::Result::Customer', 'customer_id');
    __PACKAGE__->belongs_to(shipper => 'T159B::Result::Customer', 'shipper_id', { is_foreign_key_constraint => 0 });
    T159B::Schema->register_class(Customer => 'T159B::Result::Customer');
    T159B::Schema->register_class(Orders   => 'T159B::Result::Orders');
  }
  my $ddl = DBIO::PostgreSQL::DDL->install_ddl('T159B::Schema');
  like($ddl, qr/FOREIGN KEY \(customer_id\)/, 'a belongs_to writes its key');
  unlike($ddl, qr/shipper_id\)? REFERENCES|FOREIGN KEY \(shipper_id\)/,
    'a belongs_to with is_foreign_key_constraint => 0 writes none');
  unlike($ddl, qr/skipped FK for rel shipper/, '... and leaves no note either');

  # The refusal for a class that is not loaded stays, and names the way out.
  {
    package T159C::Schema;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('PostgreSQL');
    package T159C::Result::Orders;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('orders');
    __PACKAGE__->add_columns(id => { data_type => 'integer' }, ghost_id => { data_type => 'integer' });
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->belongs_to(ghost => 'T159C::Result::Ghost', { 'foreign.id' => 'self.ghost_id' });
    T159C::Schema->register_class(Orders => 'T159C::Result::Orders');
  }
  my $bad = eval { DBIO::PostgreSQL::DDL->install_ddl('T159C::Schema') };
  ok(!defined $bad, 'a belongs_to to a class that is not loaded still refuses the install');
  like($@, qr/refusing to write the install DDL.*is_foreign_key_constraint => 0.*pg_fk_constraints_from_rels off/s,
    '... and names both ways out');

  T159C::Result::Orders->relationship_info('ghost')->{attrs}{is_foreign_key_constraint} = 0;
  my $ok = eval { DBIO::PostgreSQL::DDL->install_ddl('T159C::Schema') };
  ok(defined $ok, 'with is_foreign_key_constraint => 0 on it the install is written') or diag $@;
}

done_testing;
