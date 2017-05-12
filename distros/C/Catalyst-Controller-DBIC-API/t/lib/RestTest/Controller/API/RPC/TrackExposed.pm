package RestTest::Controller::API::RPC::TrackExposed;
use Moose;
BEGIN { extends 'Catalyst::Controller::DBIC::API::RPC' }

use namespace::autoclean;

__PACKAGE__->config
    ( action => { setup => { PathPart => 'track_exposed', Chained => '/api/rpc/rpc_base' } },
      class => 'RestTestDB::Track',
      select => [qw/position title/],
      ordered_by => [qw/position/],
      search_exposes => [qw/position/, { cd => [qw/title year pretend/, { 'artist' => ['*'] } ]}],
      );

1;
