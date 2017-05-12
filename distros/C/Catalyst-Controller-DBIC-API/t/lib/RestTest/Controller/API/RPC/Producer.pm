package RestTest::Controller::API::RPC::Producer;
use Moose;
BEGIN { extends 'Catalyst::Controller::DBIC::API::RPC' }

use namespace::autoclean;

__PACKAGE__->config
    ( action => { setup => { PathPart => 'producer', Chained => '/api/rpc/rpc_base' } },
      class => 'RestTestDB::Producer',
      create_requires => ['name'],
      create_allows => ['producerid'],
      update_allows => ['name'],
      select => ['name'],
      return_object => 1,
      );

1;
