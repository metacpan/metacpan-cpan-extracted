package RestTest::Controller::API::REST::Artist;
use Moose;
BEGIN { extends 'Catalyst::Controller::DBIC::API::REST' }
use namespace::autoclean;

__PACKAGE__->config
    ( action => { setup => { PathPart => 'artist', Chained => '/api/rest/rest_base' } },
      class => 'RestTestDB::Artist',
      create_requires => ['name'],
      create_allows => ['name'],
      update_allows => ['name'],
      prefetch_allows => [[qw/ cds /],{ 'cds' => 'tracks'}],
      );

sub action_with_error : Chained('objects_no_id') PathPart('action_with_error') Args(0) {
    my ( $self, $c ) = @_;

    $c->res->status(404);
}

1;
