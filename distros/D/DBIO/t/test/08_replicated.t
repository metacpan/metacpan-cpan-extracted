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

done_testing;
