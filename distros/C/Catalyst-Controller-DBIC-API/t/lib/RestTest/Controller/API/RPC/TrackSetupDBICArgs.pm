package RestTest::Controller::API::RPC::TrackSetupDBICArgs;
use Moose;
BEGIN { extends 'Catalyst::Controller::DBIC::API::RPC' }

use namespace::autoclean;

__PACKAGE__->config
    ( action => { setup => { PathPart => 'track_setup_dbic_args', Chained => '/api/rpc/rpc_base' } },
      class => 'RestTestDB::Track',
      select => [qw/position title/],
      ordered_by => [qw/position/],
      );

override list_munge_parameters => sub
{
	my ($self, $c) = @_;

	$c->req->search_parameters->[0]->{'me.position'} = { '!=' => '1' };
};

1;
