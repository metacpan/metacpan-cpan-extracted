package RestTest::Controller::API::REST::Track;
use Moose;
BEGIN { extends 'Catalyst::Controller::DBIC::API::REST' }

use namespace::autoclean;

__PACKAGE__->config
    ( action => { setup => { PathPart => 'track', Chained => '/api/rest/rest_base' } },
      class => 'RestTestDB::Track',
      create_requires => ['cd', 'title' ],
      create_allows => ['cd', 'title', 'position' ],
      update_allows => ['title', 'position', { cd => ['*'] }],
      page => 1,
      count => 10,
      use_json_boolean => 1,
      );

1;
