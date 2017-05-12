package RestTest::Controller::API::REST::CD_to_Producer;

use strict;
use warnings;
use JSON::XS;

use parent qw/RestTest::ControllerBase::REST/;

__PACKAGE__->config(
    # Define parent chain action and partpath
    action                  =>  { setup => { PathPart => 'cd_to_producer', Chained => '/api/rest/rest_base' } },
    # DBIC result class
    class                   =>  'DB::CD_to_Producer',

    # Columns required to create
    create_requires         =>  [qw/cd producer/],
    # Additional non-required columns that create allows
    create_allows           =>  [qw//],
    # Columns that update allows
    update_allows           =>  [qw/cd producer/],
    # Columns that list returns
    list_returns            =>  [qw/cd producer/],


    # Every possible prefetch param allowed
    list_prefetch_allows    =>  [
        [qw/cds/], {  'cds' => [qw/cd_to_producer tags tracks/] },

    ],

    # Order of generated list
    list_ordered_by         => [qw/cd producer/],
    # columns that can be searched on via list
    list_search_exposes     => [
        qw/cd producer/,

    ],);

=head1 NAME

 - REST Controller for

=head1 DESCRIPTION

REST Methods to access the DBIC Result Class cd_to_producer

=head1 AUTHOR

Amiri Barksdale,,,

=head1 SEE ALSO

L<Catalyst::Controller::DBIC::API>
L<Catalyst::Controller::DBIC::API::REST>
L<Catalyst::Controller::DBIC::API::RPC>

=head1 LICENSE



=cut

1;
