package TestAppCheckHasCol::Controller::InvalidColumn;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Controller::DBIC::API::REST';

__PACKAGE__->config(
    action => { setup => { PathPart => 'undefcol', Chained => '/api/rest/rest_base' } },
    class => 'TestAppDB::Artist',
    update_allows => ['foo'],
);

1;
