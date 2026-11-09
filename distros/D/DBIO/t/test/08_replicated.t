use strict;
use warnings;

use Test::More;

use DBIO::Test;

# Stub dbh for _dbh_columns_info_for routing tests — the base
# DBIO::Storage::DBI::_dbh_columns_info_for prefers $dbh->column_info when
# available and falls back to prepare-based introspection otherwise. Either
# path must work without real DBD machinery. We give the stub column_info
# that yields one fake column row, so the early-return path is taken — we are
# testing routing, not introspection.
{
  package DBIO::Test::StubDbh;

  sub column_info {
    my ($self, undef, undef, $tab, $col_pattern) = @_;
    return DBIO::Test::StubDbh::Sth->new([['stubcol']]);
  }
}

# Column-info result statement handle that fetchrow_hashref recognises.
{
  package DBIO::Test::StubDbh::Sth;
  our @ISA = ('DBIO::Test::Storage::FakeSth');

  sub fetchrow_hashref {
    my $self = shift;
    my $row = $self->{rows}[$self->{pos}++] or return;
    my ($name) = @$row;
    return {
      COLUMN_NAME => $name,
      TYPE_NAME   => undef,
      COLUMN_SIZE => undef,
      NULLABLE    => 1,
      COLUMN_DEF  => undef,
    };
  }
}

my $schema = DBIO::Test->init_schema(
  no_deploy => 1,
  storage_type => {
    '+DBIO::Replicated::Storage' => {
      backend_storage_class => 'DBIO::Test::Storage',
      balancer_type         => 'DBIO::Replicated::Balancer::First',
    },
  },
);

isa_ok $schema->storage, 'DBIO::Replicated::Storage', 'replicated storage created through DBIO::Test';
isa_ok $schema->storage->master, 'DBIO::Replicated::Backend::Master', 'master backend wrapped';
isa_ok $schema->storage->master->storage, 'DBIO::Test::Storage', 'master uses fake test storage';
isa_ok $schema->storage->pool, 'DBIO::Replicated::Pool', 'pool created';
isa_ok $schema->storage->balancer, 'DBIO::Replicated::Balancer::First', 'balancer created';

my @replicants = $schema->storage->connect_replicants(
  ['dbi:Test:replicant_one', '', '', { AutoCommit => 1 }],
  ['dbi:Test:replicant_two', '', '', { AutoCommit => 1 }],
);

is scalar(@replicants), 2, 'replicants connected';
isa_ok $replicants[0], 'DBIO::Replicated::Backend::Replicant', 'replicant wrapped';
isa_ok $replicants[0]->storage, 'DBIO::Test::Storage', 'replicant uses fake test storage';
ok $schema->storage->pool->has_replicants, 'pool reports replicants';

$schema->storage->master->storage->mock_persistent(
  qr/SELECT .* FROM "artist"/i,
  [[1, 'Master Artist', 13, undef]],
);
$replicants[0]->storage->mock_persistent(
  qr/SELECT .* FROM "artist"/i,
  [[1, 'Replicant Artist', 13, undef]],
);
$replicants[1]->storage->mock_persistent(
  qr/SELECT .* FROM "artist"/i,
  [[1, 'Replicant Artist Two', 13, undef]],
);

$schema->storage->master->storage->reset_captured;
$replicants[0]->storage->reset_captured;
$replicants[1]->storage->reset_captured;

my $artist = $schema->resultset('Artist')->find(1);
isa_ok $artist, 'DBIO::Test::Schema::Artist', 'read returned artist row';
is $artist->name, 'Replicant Artist', 'read routed to first replicant';
is scalar($replicants[0]->storage->captured_queries), 1, 'replicant captured read query';
is scalar($schema->storage->master->storage->captured_queries), 0, 'master did not service balanced read';

$schema->storage->master->storage->reset_captured;
$replicants[0]->storage->reset_captured;

my $reliable_artist = $schema->storage->execute_reliably(sub {
  return $schema->resultset('Artist')->find(1);
});
isa_ok $reliable_artist, 'DBIO::Test::Schema::Artist', 'reliable read returned artist row';
is $reliable_artist->name, 'Master Artist', 'reliable read routed to master';
is scalar($schema->storage->master->storage->captured_queries), 1, 'master captured reliable read';
is scalar($replicants[0]->storage->captured_queries), 0, 'replicant did not service reliable read';

$schema->storage->master->storage->reset_captured;
$replicants[0]->storage->reset_captured;

my $created = $schema->resultset('Artist')->create({ name => 'New Artist' });
isa_ok $created, 'DBIO::Test::Schema::Artist', 'write returned row object';
is scalar(grep { $_->{op} eq 'insert' } $schema->storage->master->storage->captured_queries), 1, 'write routed to master';
is scalar($replicants[0]->storage->captured_queries), 0, 'replicant did not service write';

my $hybrid_schema = DBIO::Test->init_schema(
  no_deploy => 1,
  storage_type => {
    '+DBIO::Replicated::Storage' => {
      backend_storage_type => 'DBIO::Storage::DBI::NoBindVars',
      balancer_type        => 'DBIO::Replicated::Balancer::First',
    },
  },
);

isa_ok $hybrid_schema->storage, 'DBIO::Replicated::Storage', 'replicated storage supports backend storage_type';
ok $hybrid_schema->storage->master->storage->isa('DBIO::Test::Storage'), 'hybrid backend still uses test storage';
ok $hybrid_schema->storage->master->storage->isa('DBIO::Storage::DBI::NoBindVars'), 'hybrid backend also inherits requested storage type';

# F15: Replicated reader delegation — the @reader_methods dispatch in
# Replicated::Storage forwards _select and _dbh_columns_info_for to the Balancer,
# so the Balancer must implement both. Without the fix, calling either method on
# a replicated storage dies with "Can't locate object method _select /
# _dbh_columns_info_for" because the Balancer only implements select,
# select_single, columns_info_for.
{
  my $f15_schema = DBIO::Test->init_schema(
    no_deploy => 1,
    storage_type => {
      '+DBIO::Replicated::Storage' => {
        backend_storage_class => 'DBIO::Test::Storage',
        balancer_type         => 'DBIO::Replicated::Balancer::First',
      },
    },
  );

  my @f15_replicants = $f15_schema->storage->connect_replicants(
    ['dbi:Test:f15_replicant_one', '', '', { AutoCommit => 1 }],
    ['dbi:Test:f15_replicant_two', '', '', { AutoCommit => 1 }],
  );

  # _select is the internal form of select that returns ($rv, $sth, @bind)
  # without the public-API cursor wrapping. ResultSet::results_exist depends
  # on it (see lib/DBIO/ResultSet.pm results_exist).
  my ($rv, $sth) = $f15_schema->storage->_select(
    $f15_schema->resultset('Artist')->result_source, \'*', {}, {}
  );
  ok defined $rv, '_select returns rv on replicated storage (was: latent die)';
  ok $sth, '_select returns sth on replicated storage (was: latent die)';
  ok $sth->can('fetchrow_array'), '_select sth supports fetchrow_array';
  ok $sth->can('finish'), '_select sth supports finish';

  # Exactly one of master or a replicant should have serviced the call — never both.
  my $master_hits = scalar grep { $_->{op} eq 'select' }
    $f15_schema->storage->master->storage->captured_queries;
  my $replicant_hits
    = $f15_replicants[0]->storage->captured_queries
    + $f15_replicants[1]->storage->captured_queries;
  is $master_hits + $replicant_hits, 1, '_select routed to exactly one backend';
  is $replicant_hits, 1, '_select routed to a replicant (not master) outside a transaction';

  # _dbh_columns_info_for must also exist on the Balancer and delegate to a
  # replicant by default. Same @reader_methods forwarding path.
  $f15_schema->storage->master->storage->reset_captured;
  $f15_replicants[0]->storage->reset_captured;
  $f15_replicants[1]->storage->reset_captured;

  # _dbh_columns_info_for issues no SQL (it introspects via dbh->column_info
  # / prepare), so captured_queries cannot tell us who serviced it. Wrap the
  # method on each backend storage's package with a counter instead — each
  # backend is blessed into its own DBIO::Test::Storage instance, but the
  # class-level method is shared, so we instead stash a per-storage counter
  # on the object itself and route through the Backend's AUTOLOAD.
  my $routing = {
    master         => 0,
    replicant_0    => 0,
    replicant_1    => 0,
  };

  my $master_storage = $f15_schema->storage->master->storage;
  $master_storage->{f15_dci_calls} = \$routing->{master};
  {
    no warnings 'redefine';
    *DBIO::Test::Storage::_dbh_columns_info_for = sub {
      my $self = shift;
      ${ $self->{f15_dci_calls} }++;
      return {};
    };
  }

  for my $i (0 .. $#f15_replicants) {
    my $key = "replicant_$i";
    $f15_replicants[$i]->storage->{f15_dci_calls} = \$routing->{$key};
  }

  # The real DBI base method inspects $dbh->can('column_info'); the mock
  # test storage has no real dbh, so we hand-build a stub dbh that
  # short-circuits via column_info returning one fake row.
  my $stub_dbh = bless {}, 'DBIO::Test::StubDbh';
  my $info = $f15_schema->storage->_dbh_columns_info_for($stub_dbh, 'artist');
  is ref($info), 'HASH', '_dbh_columns_info_for returns a hashref via replicant (was: latent die)';

  my $master_calls   = $routing->{master};
  my $replicant_calls = $routing->{replicant_0} + $routing->{replicant_1};
  is $master_calls + $replicant_calls, 1, '_dbh_columns_info_for routed to exactly one backend';
  is $replicant_calls, 1, '_dbh_columns_info_for routed to a replicant (not master) outside a transaction';

  # F24 / §17: _dbh_columns_info_for must use the same master-routing-in-transaction
  # guard that select/select_single use, otherwise reads inside a txn could
  # observe un-replicated state on a lagging replica.
  $routing->{master} = 0;
  $routing->{replicant_0} = 0;
  $routing->{replicant_1} = 0;

  $f15_schema->storage->txn_begin;
  eval { $f15_schema->storage->_dbh_columns_info_for($stub_dbh, 'artist'); };
  is $routing->{master}, 1, '_dbh_columns_info_for inside transaction routed to master';
  is $routing->{replicant_0} + $routing->{replicant_1}, 0, 'no replicant serviced _dbh_columns_info_for inside transaction';
  $f15_schema->storage->txn_rollback;

  # Same guard applies to _select — exercise it explicitly so a regression that
  # drops the txn guard surfaces here instead of in some downstream driver.
  $f15_schema->storage->master->storage->reset_captured;
  $f15_replicants[0]->storage->reset_captured;
  $f15_replicants[1]->storage->reset_captured;

  $f15_schema->storage->txn_begin;
  eval {
    $f15_schema->storage->_select(
      $f15_schema->resultset('Artist')->result_source, \'*', {}, {}
    );
  };
  is $f15_replicants[0]->storage->captured_queries + $f15_replicants[1]->storage->captured_queries, 0,
    '_select inside transaction did not hit a replicant';
  $f15_schema->storage->txn_rollback;

  # Cursor-holding paths must still work end-to-end: ordinary ->search goes
  # through select(), which the Balancer already implements. The cursor holds
  # a concrete replicant cursor, not a Balancer cursor — verify the read still
  # completes and rows are returned from the mocked replicant.
  $f15_replicants[0]->storage->mock_persistent(
    qr/SELECT .* FROM "artist"/i,
    [[1, 'Replicant F15', 13, undef]],
  );

  my $found = $f15_schema->resultset('Artist')->find(1);
  isa_ok $found, 'DBIO::Test::Schema::Artist', 'cursor-holding path still finds a row via replicated storage';
  is $found->name, 'Replicant F15', 'cursor-holding path read served from replicant';
}

# ADR 0037: the two engine-fact hooks must be delegated to the master backend
# like sqlt_type and sql_maker are, or a replicated setup answers them from the
# generic base class and loses the driver's rendering. except() works on a
# replicated storage today *because* sqlt_type is delegated, so leaving the
# hooks out of @writer_methods would make the fix a regression. The statement
# path results_exist runs on is a read and rides with _select.
{
  package DBIO::Test::Storage::ADR0037Backend;
  our @ISA = ('DBIO::Test::Storage');
  use mro 'c3';
  # ADR 0039: one hook for all six set operations, asked with the canonical
  # operation name. Spelling one of them and refusing another are both
  # answers a replicated setup has to be able to reach.
  sub _set_operation_keyword {
    my ($self, $op) = @_;
    return 'MINUS' if $op eq 'except';
    $self->throw_exception('ADR0037Backend has no except_all')
      if $op eq 'except_all';
    return $self->next::method($op);
  }
  sub _exists_value_sql { "SELECT CASE WHEN EXISTS $_[1] THEN 1 ELSE 0 END FROM DUAL" }
  # The older member of the same hook family, delegated for the same
  # reason -- a static class fact the driver owns.
  sub _random_function  { 'DBMS_RANDOM.VALUE' }

  # ADR 0040: its former companion _explain_sql is now
  # _explain_query and owns the whole OPERATION, in the shape that forced the
  # change -- Oracle's EXPLAIN PLAN FOR writes into PLAN_TABLE and returns no
  # rows, so the plan comes from a second statement. Both go through
  # _execute_rendered, which the contract requires.
  sub _explain_query {
    my ($self, $sql, $bind) = @_;
    $self->_execute_rendered("EXPLAIN PLAN FOR $sql", $bind);
    my (undef, $sth) = $self->_execute_rendered(
      'SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY)', [],
    );
    return $sth->fetchall_arrayref;
  }
}

{
  my $adr_schema = DBIO::Test->init_schema(
    no_deploy => 1,
    storage_type => {
      '+DBIO::Replicated::Storage' => {
        backend_storage_class => 'DBIO::Test::Storage::ADR0037Backend',
        balancer_type         => 'DBIO::Replicated::Balancer::First',
      },
    },
  );

  my @adr_replicants = $adr_schema->storage->connect_replicants(
    ['dbi:Test:adr0037_replicant', '', '', { AutoCommit => 1 }],
  );

  is $adr_schema->storage->_set_operation_keyword('except'), 'MINUS',
    '_set_operation_keyword is delegated to the master backend (was: the generic EXCEPT)';
  is $adr_schema->storage->_set_operation_keyword('union'), 'UNION',
    '... and the operations the master did not override still answer from the base';
  is $adr_schema->storage->_exists_value_sql('(SELECT 42)'),
    'SELECT CASE WHEN EXISTS (SELECT 42) THEN 1 ELSE 0 END FROM DUAL',
    '_exists_value_sql is delegated to the master backend';

  my $adr_rs = $adr_schema->resultset('Artist')
    ->search(undef, { columns => [qw( artistid name )] });

  like ${ $adr_rs->except($adr_rs)->as_query }->[0], qr/ MINUS /,
    'except() on a replicated storage still gets the driver keyword';

  # ADR 0039: the delegation carries the REFUSAL too. If it did not, the one
  # setup that hides the driver behind another storage would be the one that
  # emits SQL the engine has no operator for.
  ok !eval { $adr_rs->except_all($adr_rs); 1 },
    'except_all is refused through a replicated storage as well';
  like "$@", qr/ADR0037Backend has no except_all/,
    '... with the master backend\'s own message';

  # Same family, same list. Not a statement path -- it is the
  # spelling the master's driver dictates -- so it sits with sqlt_type and not
  # with _select.
  is $adr_schema->storage->_random_function, 'DBMS_RANDOM.VALUE',
    '_random_function is delegated to the master backend (was: the base RANDOM())';

  like ${ $adr_schema->resultset('Artist')->rand->as_query }->[0],
    qr/ORDER BY DBMS_RANDOM\.VALUE/,
    'rand() on a replicated storage renders the master driver\'s function';

  # ADR 0040: _explain_query is the one member of that family whose
  # classification FLIPPED. While it only produced a spelling, a writer was
  # right and the statement still reached the reader through _execute_rendered.
  # Now that it owns the operation, the same entry would run the EXPLAIN of a
  # READ query on the master -- undoing that very read routing. It is a reader.
  #
  # Two assertions, because there are two ways to get this wrong and each is
  # invisible to the other:
  #   * on the writer list, the statements land on the MASTER;
  #   * on NEITHER list, DBIO::Replicated::Storage answers from the generic
  #     base class -- one plain "EXPLAIN ..." on the replicant, so the routing
  #     looks right while the driver's operation is gone.
  {
    $adr_replicants[0]->storage->mock_persistent(qr/DBMS_XPLAN/, [ ['Plan hash value'] ]);
    $adr_schema->storage->master->storage->reset_captured;
    $adr_replicants[0]->storage->reset_captured;

    my $adr_plan = $adr_schema->resultset('Artist')->search({ name => 'x' })->explain;

    is_deeply $adr_plan, [ ['Plan hash value'] ],
      'explain() on a replicated storage returns the plan rows';

    is scalar($adr_schema->storage->master->storage->captured_queries), 0,
      'the EXPLAIN of a read query did NOT go to master (was: _explain_sql was '
    . 'a writer, and owning the execution would have sent it there)';

    my @adr_plan_stmts = $adr_replicants[0]->storage->captured_queries;
    is scalar(@adr_plan_stmts), 2,
      'both statements of the master driver\'s operation ran on the replicant';
    like $adr_plan_stmts[0]{sql}, qr/^EXPLAIN PLAN FOR SELECT /,
      '... the driver operation was reached, not the generic base EXPLAIN '
    . '(which is what an undelegated _explain_query would have produced)';
    like $adr_plan_stmts[1]{sql}, qr/DBMS_XPLAN/,
      '... including the second statement core never rendered';
  }

  # ... and execute_reliably still pins it to the master, like any other read.
  {
    $adr_schema->storage->master->storage->mock_persistent(qr/DBMS_XPLAN/, [ ['master plan'] ]);
    $adr_schema->storage->master->storage->reset_captured;
    $adr_replicants[0]->storage->reset_captured;

    $adr_schema->storage->execute_reliably(sub {
      $adr_schema->resultset('Artist')->search({ name => 'x' })->explain;
    });

    is scalar($adr_schema->storage->master->storage->captured_queries), 2,
      'execute_reliably routes explain() to the master, like every other read';
    is scalar($adr_replicants[0]->storage->captured_queries), 0,
      '... and the replicant saw nothing';
  }

  # ADR 0040 section 6: _prepare_rendered is the same statement
  # path stopped one verb short, for an engine whose answer is an attribute of
  # the PREPARED statement (Firebird's query plan). It rides with the method it
  # is half of, and -- like _explain_query -- needs its own forwarder on the
  # Balancer, which is not a storage and has no AUTOLOAD. Both ways of getting
  # it wrong are quiet: off the Balancer it dies on the read handler, and off
  # both lists the generic base class answers and the statement goes to
  # whatever handle that finds, with no error at all.
  {
    $adr_schema->storage->master->storage->reset_captured;
    $adr_replicants[0]->storage->reset_captured;

    my $adr_sth = $adr_schema->storage->_prepare_rendered(
      'SELECT 1 FROM "artist" WHERE "name" = ?',
      [ [ { dbic_colname => 'name' }, 'x' ] ],
    );

    ok $adr_sth, '_prepare_rendered answers through a replicated storage';
    is scalar($adr_schema->storage->master->storage->captured_queries), 0,
      '... and the prepare did not go to master outside a transaction';

    my @adr_prepared = $adr_replicants[0]->storage->captured_queries;
    is scalar(@adr_prepared), 1, '... the replicant received it';
    is $adr_prepared[0]{op}, 'prepare',
      '... as a prepare, so nothing was executed on the way to the answer';
  }

  # Probing a capability on a replicated storage has to ANSWER. The
  # driver-determination around at the top of DBIO::Storage::DBI guards on the
  # raw _driver_determined slot, which this class forwarded to its backends and
  # never set on itself, so every method on that list -- capability probes
  # included -- span in an unbounded goto loop the moment it was asked.
  is $adr_schema->storage->_use_supports_upsert, 0,
    'a capability probe on a replicated storage answers the conservative '
  . 'default (was: unbounded goto loop)';

  # The capability entry points are delegated now, so this lands on
  # the master backend -- which is where the answer is read from too. Declare
  # it here the way an operator would.
  $adr_schema->storage->_use_supports_exists_query(1);

  $adr_replicants[0]->storage->mock_persistent(qr/CASE WHEN EXISTS/, [ [ 1 ] ]);
  $adr_schema->storage->master->storage->reset_captured;
  $adr_replicants[0]->storage->reset_captured;

  is $adr_schema->resultset('Artist')->results_exist, 1,
    'results_exist runs on a replicated storage (reader delegation of _execute_rendered)';

  my ($replicant_stmt) = $adr_replicants[0]->storage->captured_queries;
  is scalar($adr_schema->storage->master->storage->captured_queries), 0,
    'the EXISTS statement did not go to master outside a transaction';
  is $replicant_stmt->{sql},
    'SELECT CASE WHEN EXISTS (SELECT 42 FROM "artist" "me") THEN 1 ELSE 0 END FROM DUAL',
    'the replicant received the master driver\'s rendering, unchanged';
}

# A capability is a fact about the engine on the other end of a
# connection. A replicated storage has no driver class and no $dbh of its own,
# so answering for itself can only ever produce the conservative default -- a
# plausible-looking lie about the cluster. Both tiers (_use_X declared by the
# driver, _supports_X probed from the handle) and both directions (get and set)
# therefore go to the master.
{
  package DBIO::Test::Storage::CapBackend;
  our @ISA = ('DBIO::Test::Storage');
  # the two ways a driver declares an engine fact
  __PACKAGE__->_use_supports_upsert(1);
  sub _determine_supports_supports_upsert_where { 1 }
}

{
  my $cap_schema = DBIO::Test->init_schema(
    no_deploy => 1,
    storage_type => {
      '+DBIO::Replicated::Storage' => {
        backend_storage_class => 'DBIO::Test::Storage::CapBackend',
        balancer_type         => 'DBIO::Replicated::Balancer::First',
      },
    },
  );

  my @cap_replicants = $cap_schema->storage->connect_replicants(
    ['dbi:Test:cap_replicant', '', '', { AutoCommit => 1 }],
  );

  my $cap_storage = $cap_schema->storage;

  # DBIO::Replicated::Storage is not a CapBackend, so its own inherited-accessor
  # lookup cannot see that class declaration -- a 1 here came from a backend.
  is $cap_storage->_use_supports_upsert, 1,
    'a capability declared on the master driver class answers through the '
  . 'replicated storage (was: the conservative default 0)';
  is $cap_storage->_supports_supports_upsert_where, 1,
    'the probed tier is the master\'s too -- _determine_supports_* runs on the '
  . 'backend that has the handle (was: 0)';
  is $cap_storage->_use_supports_upsert_where, 1,
    'the two-tier read falls through to the master as a unit, not half here '
  . 'and half there (was: 0)';

  # ... and specifically from the MASTER: declared on the master instance only,
  # so the replicant (same class) still answers the default.
  $cap_storage->master->storage->_use_supports_if_exists(1);
  is $cap_replicants[0]->storage->_use_supports_if_exists, 0,
    'the replicant does not carry this declaration';
  is $cap_storage->_use_supports_if_exists, 1,
    'the replicated storage answers with the master\'s value, not the pool\'s '
  . 'or its own default (was: 0)';

  # A declaration made on the replicated storage has to be readable back from
  # it. With only the getters delegated it would be written here and read from
  # the master, and silently lost.
  $cap_storage->_use_insert_returning(1);
  is $cap_storage->master->storage->_use_insert_returning, 1,
    'setting a capability on the replicated storage records it on the master';
  is $cap_storage->_use_insert_returning, 1,
    'and reading it back returns what was set (write here / read there closed)';

  # The one entry in the capability group that is NOT an engine fact.
  # _adjust_select_args_for_complex_prefetch forces join pruning on for the
  # inner subquery and off again once that {from} is pruned; it used to do so
  # by local()ising the raw _use_join_optimizer slot, which a delegated read
  # can no longer see. Assert the decision, not the slot: the second
  # _prune_unused_joins call of a complex-prefetch rewrite must bail out (empty
  # aliastype map), because the {from} it is handed was already pruned.
  is $cap_storage->_use_join_optimizer, 1,
    'the join-optimizer switch answers through the master like every other '
  . 'entry in the capability group';

  {
    my @pruned;
    no warnings 'redefine';
    my $orig = \&DBIO::Storage::QueryRewrite::_prune_unused_joins;
    local *DBIO::Storage::QueryRewrite::_prune_unused_joins = sub {
      my ($self, @args) = @_;
      my ($from, $aliastypes) = $orig->($self, @args);
      push @pruned, ( keys %{ $aliastypes || {} } ) ? 1 : 0;
      return ($from, $aliastypes);
    };

    $cap_schema->resultset('CD')->search(
      { 'artist.name' => 'x' },
      { join => 'artist', prefetch => 'tracks', rows => 2, order_by => 'me.cdid' },
    )->as_query;

    is_deeply \@pruned, [ 1, 0 ],
      'complex prefetch on a replicated storage prunes the inner {from} once '
    . 'and then leaves it alone (the force-off is dynamically scoped on the '
    . 'storage doing the rewrite, not borrowed from a delegated capability)';
  }
}

done_testing;
