use strict;
use warnings;

use Test::More;

use DBIO::Test;

my $schema = DBIO::Test->init_schema(
  no_deploy             => 1,
  replicated            => 1,
  storage_type          => 'DBIO::MySQL::Storage',
  replicant_connect_info => [
    ['dbi:Test:mysql_replicant', '', '', { AutoCommit => 1 }],
  ],
);

isa_ok $schema->storage, 'DBIO::Replicated::Storage', 'mysql driver can run through replicated test storage';
isa_ok $schema->storage->master->storage, 'DBIO::MySQL::Storage', 'master uses mysql storage';
is scalar($schema->storage->pool->all_replicants), 1, 'mysql replicated setup creates replicant';

$schema->storage->master->storage->reset_captured;
my ($replicant) = $schema->storage->pool->all_replicants;
isa_ok $replicant->storage, 'DBIO::MySQL::Storage', 'replicant uses mysql storage';
$replicant->storage->reset_captured;
$replicant->storage->mock_persistent(
  qr/SELECT .* FROM `artist`/i,
  [[1, 'Replicated MySQL Artist', 13, undef]],
);

my $artist = $schema->resultset('Artist')->find(1);
isa_ok $artist, 'DBIO::Test::Schema::Artist', 'mysql replicated read returns artist';
is $artist->name, 'Replicated MySQL Artist', 'mysql replicated read uses replicant';
is scalar($replicant->storage->captured_queries), 1, 'mysql replicant captured read query';

done_testing;
