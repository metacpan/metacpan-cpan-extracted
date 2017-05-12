package Test::App::Model::Search;
use Moose;
use namespace::autoclean;
extends 'Catalyst::Model::Search::ElasticSearch';

__PACKAGE__->config(
	ping_timeout => 10
);

__PACKAGE__->meta->make_immutable;
1;
