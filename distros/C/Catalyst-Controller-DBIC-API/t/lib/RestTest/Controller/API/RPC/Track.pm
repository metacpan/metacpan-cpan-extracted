package RestTest::Controller::API::RPC::Track;
use Moose;
BEGIN { extends 'Catalyst::Controller::DBIC::API::RPC' }

use namespace::autoclean;

__PACKAGE__->config
    ( action => { setup => { PathPart => 'track', Chained => '/api/rpc/rpc_base' } },
      class => 'RestTestDB::Track',
      create_requires => ['cd', 'title' ],
      create_allows => ['cd', 'title', 'position' ],
      update_allows => ['title', 'position', { cd => ['*'] }],
      grouped_by => ['position'],
      select => ['position'],
      ordered_by => ['position'],
	  search_exposes => ['title']
      );

1;
