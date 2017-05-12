package RestTest::Controller::API::REST::BoundArtist;
use Moose;
BEGIN { extends 'RestTest::Controller::API::REST::Artist'; }

use namespace::autoclean;

__PACKAGE__->config
    ( action => { setup => { PathPart => 'bound_artist', Chained => '/api/rest/rest_base' } },
      class => 'RestTestDB::Artist',
      create_requires => ['name'],
      create_allows => ['name'],
      update_allows => ['name']
      );

# Arbitrary limit
override list_munge_parameters => sub
{
    my ( $self, $c) = @_;
    # Return the first one, regardless of arguments
    $c->req->search_parameters->[0]->{'me.artistid'} = 1;
};

1;
