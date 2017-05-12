package RestTest::Controller::API::RPC::Artist;
use Moose;
BEGIN { extends 'Catalyst::Controller::DBIC::API::RPC' }

use namespace::autoclean;

__PACKAGE__->config
    ( action => { setup => { PathPart => 'artist', Chained => '/api/rpc/rpc_base' } },
      class => 'RestTestDB::Artist',
      create_requires => ['name'],
      create_allows => ['name'],
      update_allows => ['name'],
      prefetch_allows => [[qw/ cds /],{ 'cds' => 'tracks'}],
      );

1;
