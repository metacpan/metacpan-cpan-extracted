use strict;
use warnings;

use Test::More;

use DBIO::Test;

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
  qr/SELECT .* FROM artist/i,
  [[1, 'Master Artist', 13, undef]],
);
$replicants[0]->storage->mock_persistent(
  qr/SELECT .* FROM artist/i,
  [[1, 'Replicant Artist', 13, undef]],
);
$replicants[1]->storage->mock_persistent(
  qr/SELECT .* FROM artist/i,
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

done_testing;
